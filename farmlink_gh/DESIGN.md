# FarmLink Ghana - Design Document

## 🏗️ System Architecture

### High-Level Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App  │◄──►│   Supabase      │◄──►│   PostgreSQL    │
│   (Frontend)   │    │   (Backend)     │    │   (Database)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Local State  │    │   Real-time     │    │   File Storage  │
│   Management   │    │   Subscriptions │    │   (Images)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Technology Stack
- **Frontend**: Flutter 3.0+ with Dart
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Real-time)
- **State Management**: Provider pattern
- **Database**: PostgreSQL via Supabase
- **Authentication**: Supabase Auth
- **File Storage**: Supabase Storage
- **Real-time**: Supabase Realtime

## 🗄️ Database Schema

### Core Tables

#### 1. Users Table (extends Supabase auth.users)
```sql
CREATE TABLE public.users (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone_number TEXT,
    user_type TEXT NOT NULL CHECK (user_type IN ('farmer', 'buyer')),
    profile_image_url TEXT,
    location TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 2. Farmers Table
```sql
CREATE TABLE public.farmers (
    id UUID REFERENCES public.users(id) PRIMARY KEY,
    farm_name TEXT NOT NULL,
    farm_description TEXT,
    farm_size TEXT,
    farm_location TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    business_hours TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 3. Buyers Table
```sql
CREATE TABLE public.buyers (
    id UUID REFERENCES public.users(id) PRIMARY KEY,
    company_name TEXT,
    business_type TEXT,
    business_location TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 4. Products Table
```sql
CREATE TABLE public.products (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    farmer_id UUID REFERENCES public.farmers(id) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    quantity_available DECIMAL(10, 2) NOT NULL,
    unit TEXT NOT NULL, -- kg, pieces, bags, etc.
    category TEXT NOT NULL,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 5. Product Images Table
```sql
CREATE TABLE public.product_images (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 6. Messages Table
```sql
CREATE TABLE public.messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sender_id UUID REFERENCES public.users(id) NOT NULL,
    receiver_id UUID REFERENCES public.users(id) NOT NULL,
    product_id UUID REFERENCES public.products(id),
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 7. Favorites Table
```sql
CREATE TABLE public.favorites (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);
```

### Database Relationships
```
users (1) ── (1) farmers
users (1) ── (1) buyers
farmers (1) ── (many) products
products (1) ── (many) product_images
products (1) ── (many) messages
users (1) ── (many) messages (as sender)
users (1) ── (many) messages (as receiver)
users (1) ── (many) favorites
products (1) ── (many) favorites
```

## 🎨 UI/UX Design

### Design Principles
1. **Simplicity First**: Clean, uncluttered interfaces
2. **Mobile-First**: Optimized for mobile devices
3. **Accessibility**: Easy to use for all ages and tech levels
4. **Ghanaian Context**: Culturally appropriate colors and language
5. **Fast Performance**: Quick loading and smooth interactions

### Color Scheme
- **Primary**: Green (#2E7D32) - Represents agriculture and growth
- **Secondary**: Orange (#FF9800) - Represents harvest and abundance
- **Accent**: Blue (#2196F3) - Represents trust and reliability
- **Background**: Light Gray (#F5F5F5) - Clean, easy on eyes
- **Text**: Dark Gray (#212121) - Good readability
- **Success**: Green (#4CAF50) - Positive actions
- **Warning**: Orange (#FF9800) - Attention needed
- **Error**: Red (#F44336) - Error states

### Typography
- **Headings**: Roboto Bold - Clear hierarchy
- **Body Text**: Roboto Regular - Easy reading
- **Buttons**: Roboto Medium - Clear call-to-action
- **Sizes**: 16px base, scalable for accessibility

### Screen Layouts

#### 1. Authentication Screens
```
┌─────────────────────────────────┐
│           FarmLink              │
│            Ghana                │
├─────────────────────────────────┤
│                                 │
│    [Farmer] [Buyer]            │
│                                 │
│    ┌─────────────────────┐     │
│    │   Registration      │     │
│    │      Form           │     │
│    └─────────────────────┘     │
│                                 │
│    [Already have account?]     │
│    [Login]                     │
└─────────────────────────────────┘
```

#### 2. Farmer Dashboard
```
┌─────────────────────────────────┐
│ [Menu] FarmLink Ghana [Profile] │
├─────────────────────────────────┤
│                                 │
│    Welcome, [Farmer Name]       │
│                                 │
│    ┌─────┐ ┌─────┐ ┌─────┐     │
│    │Add  │ │View │ │Orders│     │
│    │Prod │ │Prod │ │     │     │
│    └─────┘ └─────┘ └─────┘     │
│                                 │
│    Recent Products:              │
│    ┌─────────────────────┐     │
│    │ Product Card 1      │     │
│    │ Product Card 2      │     │
│    └─────────────────────┘     │
└─────────────────────────────────┘
```

#### 3. Buyer Browse Screen
```
┌─────────────────────────────────┐
│ [Menu] FarmLink Ghana [Profile] │
├─────────────────────────────────┤
│                                 │
│    ┌─────────────────────┐     │
│    │ 🔍 Search Products │     │
│    └─────────────────────┘     │
│                                 │
│    Filters: [Location] [Type]   │
│                                 │
│    Available Products:           │
│    ┌─────┐ ┌─────┐ ┌─────┐     │
│    │Prod │ │Prod │ │Prod │     │
│    │Card │ │Card │ │Card │     │
│    └─────┘ └─────┘ └─────┘     │
│                                 │
│    [Load More]                  │
└─────────────────────────────────┘
```

#### 4. Product Detail Screen
```
┌─────────────────────────────────┐
│ [← Back] Product Details       │
├─────────────────────────────────┤
│                                 │
│    ┌─────────────────────┐     │
│    │   Product Images    │     │
│    │   (Carousel)        │     │
│    └─────────────────────┘     │
│                                 │
│    Product Name                 │
│    Price: GHS XX.XX            │
│    Quantity: XX kg available   │
│                                 │
│    Description:                 │
│    [Product description text]   │
│                                 │
│    Farmer: [Farmer Name]       │
│    Location: [Farm Location]    │
│                                 │
│    [❤️ Favorite] [📞 Contact]  │
└─────────────────────────────────┘
```

## 🔄 Data Flow

### User Registration Flow
```
1. User opens app
2. Selects user type (Farmer/Buyer)
3. Fills registration form
4. Creates Supabase auth account
5. Creates user profile
6. Creates type-specific profile (farmer/buyer)
7. Redirects to appropriate dashboard
```

### Product Creation Flow
```
1. Farmer navigates to "Add Product"
2. Fills product form (name, description, price, quantity)
3. Uploads product images
4. Saves to products table
5. Images uploaded to Supabase Storage
6. Product appears in buyer browse
7. Real-time update to all connected buyers
```

### Buyer Inquiry Flow
```
1. Buyer browses products
2. Clicks on product of interest
3. Views product details
4. Clicks "Contact Farmer"
5. Sends message through messaging system
6. Farmer receives real-time notification
7. Farmer can respond through app
```

## 📱 Screen Navigation

### Navigation Structure
```
App Entry
├── Authentication
│   ├── User Type Selection
│   ├── Farmer Registration
│   ├── Buyer Registration
│   └── Login
├── Farmer Flow
│   ├── Dashboard
│   ├── Add Product
│   ├── My Products
│   ├── Messages
│   └── Profile
└── Buyer Flow
    ├── Browse Products
    ├── Product Details
    ├── Messages
    ├── Favorites
    └── Profile
```

## 🔐 Security & Privacy

### Data Protection
- **User Authentication**: Supabase Auth with JWT tokens
- **Data Encryption**: All data encrypted in transit and at rest
- **Privacy Controls**: Users control their data visibility
- **Input Validation**: Server-side validation for all inputs
- **Rate Limiting**: Protection against abuse

### User Permissions
- **Farmers**: Can only edit their own products and profiles
- **Buyers**: Can only view products and send messages
- **Data Isolation**: Users cannot access other users' private data
- **Admin Access**: Limited admin functions for moderation

## 📊 Performance Considerations

### Optimization Strategies
- **Image Compression**: Optimize product images before upload
- **Lazy Loading**: Load products as needed
- **Caching**: Cache frequently accessed data
- **Pagination**: Limit data loaded at once
- **Offline Support**: Basic functionality without internet

### Scalability
- **Database Indexing**: Optimize queries for large datasets
- **CDN**: Use Supabase Edge Functions for global performance
- **Real-time**: Efficient real-time subscriptions
- **Storage**: Optimize image storage and delivery
