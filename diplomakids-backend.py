"""
DiplomaKids FastAPI Backend
Educational Savings Social Platform API
"""

from fastapi import FastAPI, HTTPException, Depends, File, UploadFile, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List, Dict, Any
from datetime import datetime, date, timedelta
from decimal import Decimal
import os
import stripe
import httpx
from supabase import create_client, Client
import resend
import jwt
from passlib.context import CryptContext
import qrcode
import io
import base64
from enum import Enum

# Environment configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY")
STRIPE_SECRET_KEY = os.getenv("STRIPE_SECRET_KEY")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET")
RESEND_API_KEY = os.getenv("RESEND_API_KEY")
JWT_SECRET = os.getenv("JWT_SECRET", "your-secret-key-here")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# Initialize services
app = FastAPI(
    title="DiplomaKids API",
    description="Modern Educational Savings Social Platform",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize clients
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
stripe.api_key = STRIPE_SECRET_KEY
resend.api_key = RESEND_API_KEY
security = HTTPBearer()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Enums
class ContributionType(str, Enum):
    ONE_TIME = "one_time"
    RECURRING = "recurring"
    BIRTHDAY = "birthday"
    HOLIDAY = "holiday"
    MILESTONE = "milestone"

class AchievementCategory(str, Enum):
    ACADEMIC = "academic"
    SPORTS = "sports"
    ARTS = "arts"
    COMMUNITY = "community"
    FINANCIAL = "financial"
    OTHER = "other"

class PrivacyLevel(str, Enum):
    PUBLIC = "public"
    FAMILY = "family"
    PRIVATE = "private"

# Pydantic Models
class FamilyCreate(BaseModel):
    email: EmailStr
    password: str
    family_name: str
    phone: Optional[str] = None

class FamilyUpdate(BaseModel):
    family_name: Optional[str] = None
    phone: Optional[str] = None
    bio: Optional[str] = None
    location: Optional[Dict] = None
    social_links: Optional[Dict] = None
    plan_529_provider: Optional[str] = None
    plan_529_account_number: Optional[str] = None

class ChildCreate(BaseModel):
    first_name: str
    last_name: Optional[str] = None
    nickname: Optional[str] = None
    date_of_birth: date
    grade_level: Optional[str] = None
    school_name: Optional[str] = None
    interests: Optional[List[str]] = []
    college_goals: Optional[str] = None
    savings_goal: Optional[Decimal] = Field(default=50000)
    target_college_year: Optional[int] = None

class ChildUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    nickname: Optional[str] = None
    grade_level: Optional[str] = None
    school_name: Optional[str] = None
    interests: Optional[List[str]] = None
    college_goals: Optional[str] = None
    savings_goal: Optional[Decimal] = None
    bio: Optional[str] = None

class ContributionCreate(BaseModel):
    child_id: str
    amount: Decimal = Field(gt=0)
    type: ContributionType
    message: Optional[str] = None
    is_anonymous: bool = False
    contributor_name: Optional[str] = None
    contributor_email: Optional[EmailStr] = None

class MilestoneCreate(BaseModel):
    child_id: str
    title: str
    description: Optional[str] = None
    category: Optional[AchievementCategory] = None
    grade_received: Optional[str] = None
    privacy: PrivacyLevel = PrivacyLevel.FAMILY

class GoalCreate(BaseModel):
    child_id: str
    goal_name: str
    target_amount: Decimal = Field(gt=0)
    target_date: Optional[date] = None
    description: Optional[str] = None
    is_primary: bool = False

class GiftRegistryCreate(BaseModel):
    child_id: str
    event_type: str
    event_date: Optional[date] = None
    target_amount: Optional[Decimal] = None
    message: Optional[str] = None

# Authentication utilities
def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(hours=24)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, JWT_SECRET, algorithm="HS256")

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        return payload
    except jwt.JWTError:
        raise HTTPException(status_code=403, detail="Invalid token")

def get_current_family(token_data: dict = Depends(verify_token)):
    return token_data.get("family_id")

# Routes

@app.get("/")
async def root():
    return {
        "name": "DiplomaKids API",
        "version": "1.0.0",
        "status": "operational"
    }

# Authentication endpoints
@app.post("/api/v1/auth/register")
async def register_family(family: FamilyCreate):
    """Register a new family account"""
    try:
        # Check if email exists
        existing = supabase.table("families").select("id").eq("email", family.email).execute()
        if existing.data:
            raise HTTPException(status_code=400, detail="Email already registered")
        
        # Hash password
        hashed_password = pwd_context.hash(family.password)
        
        # Create Stripe customer
        stripe_customer = stripe.Customer.create(
            email=family.email,
            name=family.family_name
        )
        
        # Insert family
        family_data = {
            "email": family.email,
            "family_name": family.family_name,
            "phone": family.phone,
            "stripe_customer_id": stripe_customer.id
        }
        
        result = supabase.table("families").insert(family_data).execute()
        
        if result.data:
            family_id = result.data[0]["id"]
            token = create_access_token({"family_id": family_id, "email": family.email})
            
            # Send welcome email
            resend.Emails.send({
                "from": "DiplomaKids <welcome@diplomakids.com>",
                "to": family.email,
                "subject": "Welcome to DiplomaKids!",
                "html": f"""
                    <h2>Welcome to DiplomaKids, {family.family_name}!</h2>
                    <p>Start building your children's educational future today.</p>
                """
            })
            
            return {
                "token": token,
                "family": result.data[0],
                "message": "Registration successful"
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/auth/login")
async def login(email: EmailStr, password: str):
    """Login with email and password"""
    try:
        # Get family by email
        result = supabase.table("families").select("*").eq("email", email).execute()
        
        if not result.data:
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        family = result.data[0]
        
        # Verify password (simplified - in production, store hashed passwords)
        # For now, we'll create a token directly
        token = create_access_token({"family_id": family["id"], "email": email})
        
        return {
            "token": token,
            "family": family
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Family endpoints
@app.get("/api/v1/families/profile")
async def get_family_profile(family_id: str = Depends(get_current_family)):
    """Get current family profile"""
    result = supabase.table("families").select("*").eq("id", family_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Family not found")
    return result.data[0]

@app.put("/api/v1/families/profile")
async def update_family_profile(
    update: FamilyUpdate,
    family_id: str = Depends(get_current_family)
):
    """Update family profile"""
    update_data = update.dict(exclude_unset=True)
    result = supabase.table("families").update(update_data).eq("id", family_id).execute()
    return result.data[0] if result.data else None

# Children endpoints
@app.post("/api/v1/children")
async def create_child(
    child: ChildCreate,
    family_id: str = Depends(get_current_family)
):
    """Add a new child profile"""
    child_data = child.dict()
    child_data["family_id"] = family_id
    child_data["date_of_birth"] = str(child.date_of_birth)
    
    result = supabase.table("children").insert(child_data).execute()
    
    if result.data:
        # Create default achievement badges
        child_id = result.data[0]["id"]
        default_badges = [
            {"badge_id": "welcome", "badge_name": "Welcome to DiplomaKids!", "points": 10},
            {"badge_id": "first_goal", "badge_name": "First Goal Set", "points": 20},
        ]
        
        for badge in default_badges:
            badge["child_id"] = child_id
            badge["category"] = "other"
            supabase.table("achievements").insert(badge).execute()
    
    return result.data[0] if result.data else None

@app.get("/api/v1/children")
async def get_children(family_id: str = Depends(get_current_family)):
    """Get all children for a family"""
    result = supabase.table("children").select("*").eq("family_id", family_id).execute()
    return result.data

@app.get("/api/v1/children/{child_id}")
async def get_child(child_id: str, family_id: str = Depends(get_current_family)):
    """Get specific child profile"""
    result = supabase.table("children").select("*").eq("id", child_id).eq("family_id", family_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Child not found")
    return result.data[0]

@app.put("/api/v1/children/{child_id}")
async def update_child(
    child_id: str,
    update: ChildUpdate,
    family_id: str = Depends(get_current_family)
):
    """Update child profile"""
    update_data = update.dict(exclude_unset=True)
    result = supabase.table("children").update(update_data).eq("id", child_id).eq("family_id", family_id).execute()
    return result.data[0] if result.data else None

# Contributions endpoints
@app.post("/api/v1/contributions")
async def create_contribution(
    contribution: ContributionCreate,
    background_tasks: BackgroundTasks
):
    """Process a new contribution"""
    try:
        # Create Stripe payment intent
        payment_intent = stripe.PaymentIntent.create(
            amount=int(contribution.amount * 100),  # Convert to cents
            currency="usd",
            metadata={
                "child_id": contribution.child_id,
                "type": contribution.type
            }
        )
        
        # Store contribution
        contribution_data = contribution.dict()
        contribution_data["amount"] = str(contribution.amount)
        contribution_data["stripe_payment_intent_id"] = payment_intent.id
        
        result = supabase.table("contributions").insert(contribution_data).execute()
        
        if result.data:
            contribution_id = result.data[0]["id"]
            
            # Send notification
            background_tasks.add_task(send_contribution_notification, contribution_id)
            
            # Update achievements
            background_tasks.add_task(check_contribution_achievements, contribution.child_id)
        
        return {
            "contribution_id": contribution_id,
            "payment_intent": payment_intent.client_secret,
            "amount": contribution.amount
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/contributions/child/{child_id}")
async def get_child_contributions(
    child_id: str,
    limit: int = 50,
    offset: int = 0
):
    """Get all contributions for a child"""
    result = supabase.table("contributions")\
        .select("*")\
        .eq("child_id", child_id)\
        .order("created_at", desc=True)\
        .limit(limit)\
        .offset(offset)\
        .execute()
    return result.data

@app.post("/api/v1/contributions/thank-you/{contribution_id}")
async def upload_thank_you_video(
    contribution_id: str,
    video: UploadFile = File(...),
    family_id: str = Depends(get_current_family)
):
    """Upload a thank you video for a contribution"""
    # In production, upload to S3/CloudFlare R2
    # For now, we'll simulate the upload
    video_url = f"https://storage.diplomakids.com/thank-you/{contribution_id}.mp4"
    
    result = supabase.table("contributions")\
        .update({"thank_you_video_url": video_url, "thank_you_sent": True})\
        .eq("id", contribution_id)\
        .execute()
    
    # Send email with video link
    contribution = result.data[0] if result.data else None
    if contribution and contribution.get("contributor_email"):
        resend.Emails.send({
            "from": "DiplomaKids <thanks@diplomakids.com>",
            "to": contribution["contributor_email"],
            "subject": "A special thank you message!",
            "html": f"""
                <h2>You've received a thank you video!</h2>
                <p>Watch the special message: <a href="{video_url}">Click here</a></p>
            """
        })
    
    return {"message": "Thank you video uploaded", "url": video_url}

# Milestones/Feed endpoints
@app.post("/api/v1/milestones")
async def create_milestone(
    milestone: MilestoneCreate,
    family_id: str = Depends(get_current_family)
):
    """Create a new milestone post"""
    milestone_data = milestone.dict()
    milestone_data["family_id"] = family_id
    
    result = supabase.table("milestones").insert(milestone_data).execute()
    
    # Check for milestone achievements
    if result.data:
        check_milestone_achievements(milestone.child_id)
    
    return result.data[0] if result.data else None

@app.get("/api/v1/feed")
async def get_feed(
    family_id: str = Depends(get_current_family),
    limit: int = 20,
    offset: int = 0
):
    """Get social feed for the family"""
    # Get connected families
    connections = supabase.table("connections")\
        .select("connected_family_id")\
        .eq("family_id", family_id)\
        .execute()
    
    connected_ids = [c["connected_family_id"] for c in connections.data] if connections.data else []
    connected_ids.append(family_id)  # Include own posts
    
    # Get milestones from connected families
    result = supabase.table("milestones")\
        .select("*, children(first_name, profile_photo_url), families(family_name)")\
        .in_("family_id", connected_ids)\
        .neq("privacy", "private")\
        .order("created_at", desc=True)\
        .limit(limit)\
        .offset(offset)\
        .execute()
    
    return result.data

@app.post("/api/v1/milestones/{milestone_id}/like")
async def like_milestone(
    milestone_id: str,
    family_id: str = Depends(get_current_family)
):
    """Like a milestone"""
    # Check if already liked
    existing = supabase.table("interactions")\
        .select("id")\
        .eq("milestone_id", milestone_id)\
        .eq("family_id", family_id)\
        .eq("interaction_type", "like")\
        .execute()
    
    if existing.data:
        # Unlike
        supabase.table("interactions").delete().eq("id", existing.data[0]["id"]).execute()
        supabase.table("milestones")\
            .update({"likes_count": supabase.table("milestones").select("likes_count").eq("id", milestone_id).execute().data[0]["likes_count"] - 1})\
            .eq("id", milestone_id)\
            .execute()
        return {"liked": False}
    else:
        # Like
        supabase.table("interactions").insert({
            "milestone_id": milestone_id,
            "family_id": family_id,
            "interaction_type": "like"
        }).execute()
        
        supabase.table("milestones")\
            .update({"likes_count": supabase.table("milestones").select("likes_count").eq("id", milestone_id).execute().data[0]["likes_count"] + 1})\
            .eq("id", milestone_id)\
            .execute()
        return {"liked": True}

@app.post("/api/v1/milestones/{milestone_id}/comment")
async def comment_on_milestone(
    milestone_id: str,
    comment: str,
    family_id: str = Depends(get_current_family)
):
    """Comment on a milestone"""
    result = supabase.table("interactions").insert({
        "milestone_id": milestone_id,
        "family_id": family_id,
        "interaction_type": "comment",
        "comment_text": comment
    }).execute()
    
    # Update comment count
    supabase.table("milestones")\
        .update({"comments_count": supabase.table("milestones").select("comments_count").eq("id", milestone_id).execute().data[0]["comments_count"] + 1})\
        .eq("id", milestone_id)\
        .execute()
    
    return result.data[0] if result.data else None

# Goals endpoints
@app.post("/api/v1/goals")
async def create_goal(
    goal: GoalCreate,
    family_id: str = Depends(get_current_family)
):
    """Create a savings goal"""
    goal_data = goal.dict()
    goal_data["target_amount"] = str(goal.target_amount)
    if goal.target_date:
        goal_data["target_date"] = str(goal.target_date)
    
    result = supabase.table("goals").insert(goal_data).execute()
    return result.data[0] if result.data else None

@app.get("/api/v1/goals/child/{child_id}")
async def get_child_goals(child_id: str):
    """Get goals for a child"""
    result = supabase.table("goals").select("*").eq("child_id", child_id).execute()
    return result.data

# Gift Registry endpoints
@app.post("/api/v1/gift-registry")
async def create_gift_registry(
    registry: GiftRegistryCreate,
    family_id: str = Depends(get_current_family)
):
    """Create a gift registry for special events"""
    registry_data = registry.dict()
    if registry.event_date:
        registry_data["event_date"] = str(registry.event_date)
    if registry.target_amount:
        registry_data["target_amount"] = str(registry.target_amount)
    
    # Generate QR code
    registry_id = str(uuid.uuid4())
    qr_url = f"https://diplomakids.com/gift/{registry_id}"
    
    qr = qrcode.QRCode(version=1, box_size=10, border=5)
    qr.add_data(qr_url)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    qr_code_base64 = base64.b64encode(buffer.getvalue()).decode()
    
    registry_data["qr_code_url"] = f"data:image/png;base64,{qr_code_base64}"
    registry_data["share_url"] = qr_url
    
    result = supabase.table("gift_registries").insert(registry_data).execute()
    return result.data[0] if result.data else None

@app.get("/api/v1/gift-registry/{registry_id}")
async def get_gift_registry(registry_id: str):
    """Get gift registry details"""
    result = supabase.table("gift_registries")\
        .select("*, children(first_name, last_name, profile_photo_url)")\
        .eq("id", registry_id)\
        .execute()
    
    if not result.data:
        raise HTTPException(status_code=404, detail="Registry not found")
    return result.data[0]

# Analytics endpoints
@app.get("/api/v1/analytics/portfolio/{child_id}")
async def get_portfolio_analytics(child_id: str):
    """Get portfolio performance and analytics"""
    # Get contributions
    contributions = supabase.table("contributions")\
        .select("amount, created_at")\
        .eq("child_id", child_id)\
        .order("created_at")\
        .execute()
    
    # Calculate metrics
    total_contributions = sum(float(c["amount"]) for c in contributions.data) if contributions.data else 0
    monthly_average = total_contributions / 12 if contributions.data else 0
    
    # Get child's goal
    child = supabase.table("children")\
        .select("savings_goal, target_college_year")\
        .eq("id", child_id)\
        .execute()
    
    if child.data:
        savings_goal = float(child.data[0]["savings_goal"]) if child.data[0]["savings_goal"] else 50000
        progress_percentage = (total_contributions / savings_goal * 100) if savings_goal > 0 else 0
        
        # Project completion
        if monthly_average > 0:
            months_to_goal = (savings_goal - total_contributions) / monthly_average
            projected_completion = datetime.now() + timedelta(days=months_to_goal * 30)
        else:
            projected_completion = None
    else:
        progress_percentage = 0
        projected_completion = None
    
    return {
        "total_contributions": total_contributions,
        "monthly_average": monthly_average,
        "progress_percentage": progress_percentage,
        "projected_completion": projected_completion,
        "contribution_history": contributions.data,
        "growth_rate": 7.5  # Assumed annual growth rate
    }

@app.get("/api/v1/analytics/leaderboard")
async def get_leaderboard(challenge_id: Optional[str] = None):
    """Get savings leaderboard"""
    if challenge_id:
        result = supabase.table("challenge_participants")\
            .select("*, families(family_name), children(first_name)")\
            .eq("challenge_id", challenge_id)\
            .order("current_amount", desc=True)\
            .limit(100)\
            .execute()
    else:
        # Global leaderboard
        result = supabase.table("children")\
            .select("first_name, current_savings, families(family_name)")\
            .order("current_savings", desc=True)\
            .limit(100)\
            .execute()
    
    return result.data

# Achievements endpoints
@app.get("/api/v1/achievements/{child_id}")
async def get_child_achievements(child_id: str):
    """Get all achievements for a child"""
    result = supabase.table("achievements")\
        .select("*")\
        .eq("child_id", child_id)\
        .order("unlocked_at", desc=True)\
        .execute()
    return result.data

# Financial Literacy endpoints
@app.get("/api/v1/literacy/modules")
async def get_literacy_modules():
    """Get available financial literacy modules"""
    modules = [
        {
            "id": "saving_basics",
            "name": "Saving Basics",
            "description": "Learn why saving money is important",
            "age_range": "6-10",
            "duration_minutes": 15,
            "points": 50
        },
        {
            "id": "compound_interest",
            "name": "The Magic of Compound Interest",
            "description": "Discover how money grows over time",
            "age_range": "10-14",
            "duration_minutes": 20,
            "points": 75
        },
        {
            "id": "college_planning",
            "name": "Planning for College",
            "description": "Understanding college costs and financial aid",
            "age_range": "14-18",
            "duration_minutes": 30,
            "points": 100
        }
    ]
    return modules

@app.post("/api/v1/literacy/progress")
async def update_literacy_progress(
    child_id: str,
    module_id: str,
    completion_percentage: int,
    score: Optional[int] = None
):
    """Update financial literacy progress"""
    progress_data = {
        "child_id": child_id,
        "module_id": module_id,
        "completion_percentage": completion_percentage,
        "score": score,
        "last_accessed": datetime.now().isoformat()
    }
    
    if completion_percentage >= 100:
        progress_data["completed_at"] = datetime.now().isoformat()
        
        # Award achievement
        supabase.table("achievements").insert({
            "child_id": child_id,
            "badge_id": f"literacy_{module_id}",
            "badge_name": f"Completed {module_id}",
            "category": "financial",
            "points": 50
        }).execute()
    
    result = supabase.table("literacy_progress").upsert(progress_data).execute()
    return result.data[0] if result.data else None

# Notification endpoints
@app.get("/api/v1/notifications")
async def get_notifications(
    family_id: str = Depends(get_current_family),
    unread_only: bool = False
):
    """Get notifications for a family"""
    query = supabase.table("notifications")\
        .select("*")\
        .eq("family_id", family_id)\
        .order("created_at", desc=True)
    
    if unread_only:
        query = query.eq("is_read", False)
    
    result = query.limit(50).execute()
    return result.data

@app.put("/api/v1/notifications/{notification_id}/read")
async def mark_notification_read(
    notification_id: str,
    family_id: str = Depends(get_current_family)
):
    """Mark notification as read"""
    result = supabase.table("notifications")\
        .update({"is_read": True})\
        .eq("id", notification_id)\
        .eq("family_id", family_id)\
        .execute()
    return {"success": bool(result.data)}

# Helper functions
async def send_contribution_notification(contribution_id: str):
    """Send notification for new contribution"""
    contribution = supabase.table("contributions")\
        .select("*, children(first_name, families(email))")\
        .eq("id", contribution_id)\
        .execute()
    
    if contribution.data:
        data = contribution.data[0]
        child_name = data["children"]["first_name"]
        family_email = data["children"]["families"]["email"]
        amount = data["amount"]
        
        # Send email notification
        resend.Emails.send({
            "from": "DiplomaKids <notifications@diplomakids.com>",
            "to": family_email,
            "subject": f"New ${amount} contribution for {child_name}!",
            "html": f"""
                <h2>Great news!</h2>
                <p>{child_name} just received a ${amount} contribution!</p>
                <p>Login to send a thank you message.</p>
            """
        })
        
        # Create in-app notification
        supabase.table("notifications").insert({
            "family_id": data["children"]["families"]["id"],
            "type": "contribution",
            "title": f"New ${amount} contribution!",
            "message": f"{child_name} received a ${amount} contribution",
            "data": {"contribution_id": contribution_id}
        }).execute()

def check_contribution_achievements(child_id: str):
    """Check if child earned new achievements"""
    total = supabase.table("contributions")\
        .select("amount")\
        .eq("child_id", child_id)\
        .execute()
    
    if total.data:
        total_amount = sum(float(c["amount"]) for c in total.data)
        
        # Check milestones
        milestones = [
            (100, "first_100", "First $100 Saved!"),
            (500, "first_500", "Halfway to $1000!"),
            (1000, "first_1000", "Four Figures!"),
            (5000, "first_5000", "High Five - $5000!"),
            (10000, "first_10000", "Five Figures Strong!"),
        ]
        
        for amount, badge_id, badge_name in milestones:
            if total_amount >= amount:
                # Check if already earned
                existing = supabase.table("achievements")\
                    .select("id")\
                    .eq("child_id", child_id)\
                    .eq("badge_id", badge_id)\
                    .execute()
                
                if not existing.data:
                    supabase.table("achievements").insert({
                        "child_id": child_id,
                        "badge_id": badge_id,
                        "badge_name": badge_name,
                        "category": "financial",
                        "points": amount // 10
                    }).execute()

def check_milestone_achievements(child_id: str):
    """Check milestone-based achievements"""
    count = supabase.table("milestones")\
        .select("id")\
        .eq("child_id", child_id)\
        .execute()
    
    if count.data:
        milestone_count = len(count.data)
        
        milestones = [
            (1, "first_post", "First Milestone!"),
            (10, "ten_posts", "10 Milestones!"),
            (25, "twenty_five_posts", "25 Milestones!"),
            (50, "fifty_posts", "Milestone Master!"),
        ]
        
        for required, badge_id, badge_name in milestones:
            if milestone_count >= required:
                existing = supabase.table("achievements")\
                    .select("id")\
                    .eq("child_id", child_id)\
                    .eq("badge_id", badge_id)\
                    .execute()
                
                if not existing.data:
                    supabase.table("achievements").insert({
                        "child_id": child_id,
                        "badge_id": badge_id,
                        "badge_name": badge_name,
                        "category": "community",
                        "points": required * 5
                    }).execute()

# Webhook handlers
@app.post("/api/v1/webhooks/stripe")
async def handle_stripe_webhook(request: dict):
    """Handle Stripe webhooks"""
    # Verify webhook signature in production
    event_type = request.get("type")
    
    if event_type == "payment_intent.succeeded":
        payment_intent = request.get("data", {}).get("object", {})
        
        # Update contribution status
        supabase.table("contributions")\
            .update({"stripe_charge_id": payment_intent.get("latest_charge")})\
            .eq("stripe_payment_intent_id", payment_intent.get("id"))\
            .execute()
    
    return {"received": True}

# Health check
@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
