-- 1. Enable UUID Extension (if not already enabled)
-- This is necessary for UUID generation functions like gen_random_uuid() or uuid_generate_v4()
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Define ENUM Types
-- These correspond to your ENUM fields in the DBML
CREATE TYPE user_role_enum AS ENUM ('guest', 'host', 'admin');
CREATE TYPE booking_status_enum AS ENUM ('pending', 'confirmed', 'cancelled', 'completed');

-- 3. Create Tables

-- Table: users
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    role user_role_enum NOT NULL DEFAULT 'guest',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: properties
CREATE TABLE properties (
    property_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(255) NOT NULL,
    price_per_night DECIMAL(10, 2) NOT NULL,
    number_of_rooms INT NOT NULL,
    number_of_bathrooms INT NOT NULL,
    max_guests INT NOT NULL,
    -- 'amenities' TEXT column removed as per 3NF normalization
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_properties_host
        FOREIGN KEY (host_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE -- If a host user is deleted, their properties are also deleted
);

-- Optional PostgreSQL Trigger for updated_at (to mimic ON UPDATE CURRENT_TIMESTAMP)
/*
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_properties_updated_at_trigger
BEFORE UPDATE ON properties
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
*/

-- Table: bookings
CREATE TABLE bookings (
    booking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guest_id UUID NOT NULL,
    property_id UUID NOT NULL,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    status booking_status_enum NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_bookings_guest
        FOREIGN KEY (guest_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_bookings_property
        FOREIGN KEY (property_id)
        REFERENCES properties(property_id)
        ON DELETE CASCADE
);

-- Table: reviews
CREATE TABLE reviews (
    review_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL,
    -- 'reviewer_id' and 'property_id' columns removed as per 3NF normalization
    rating INT NOT NULL,
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT chk_reviews_rating CHECK (rating >= 1 AND rating <= 5),
    CONSTRAINT fk_reviews_booking
        FOREIGN KEY (booking_id)
        REFERENCES bookings(booking_id)
        ON DELETE CASCADE -- If a booking is deleted, its reviews are also deleted
);

-- Table: amenities
CREATE TABLE amenities (
    amenity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT
);

-- Table: property_amenities (Junction Table)
CREATE TABLE property_amenities (
    property_id UUID NOT NULL,
    amenity_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (property_id, amenity_id), -- Composite Primary Key
    CONSTRAINT fk_prop_amen_property
        FOREIGN KEY (property_id)
        REFERENCES properties(property_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_prop_amen_amenity
        FOREIGN KEY (amenity_id)
        REFERENCES amenities(amenity_id)
        ON DELETE CASCADE
);

-- Optional: Table for Payments (based on your initial specification, not in the last DBML but good to include)
-- If you need payments, add this table and its ENUM type:
/*
CREATE TYPE payment_method_enum AS ENUM ('credit_card', 'paypal', 'stripe');

CREATE TABLE payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    payment_method payment_method_enum NOT NULL,
    CONSTRAINT fk_payments_booking
        FOREIGN KEY (booking_id)
        REFERENCES bookings(booking_id)
        ON DELETE CASCADE
);
*/

-- Optional: Table for Messages (based on your initial specification, not in the last DBML but good to include)
/*
CREATE TABLE messages (
    message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL,
    recipient_id UUID NOT NULL,
    message_body TEXT NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_messages_sender
        FOREIGN KEY (sender_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_messages_recipient
        FOREIGN KEY (recipient_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);
*/


-- 4. Create Indexes for Optimal Performance

-- Indexes are automatically created for PRIMARY KEY and UNIQUE constraints.
-- However, creating explicit indexes on Foreign Key columns is highly recommended
-- for efficient joins and lookups.

-- Index on properties.host_id for efficient lookup of properties by host
CREATE INDEX idx_properties_host_id ON properties (host_id);

-- Index on bookings.guest_id for efficient lookup of bookings by guest
CREATE INDEX idx_bookings_guest_id ON bookings (guest_id);

-- Index on bookings.property_id for efficient lookup of bookings by property
CREATE INDEX idx_bookings_property_id ON bookings (property_id);

-- Index on reviews.booking_id for efficient lookup of reviews by booking
CREATE INDEX idx_reviews_booking_id ON reviews (booking_id);

-- Indexes on property_amenities foreign keys (composite PK already covers these, but individual FK indexes can be useful too)
CREATE INDEX idx_property_amenities_property_id ON property_amenities (property_id);
CREATE INDEX idx_property_amenities_amenity_id ON property_amenities (amenity_id);

-- If you include Payments table:
-- CREATE INDEX idx_payments_booking_id ON payments (booking_id);

-- If you include Messages table:
-- CREATE INDEX idx_messages_sender_id ON messages (sender_id);
-- CREATE INDEX idx_messages_recipient_id ON messages (recipient_id);
