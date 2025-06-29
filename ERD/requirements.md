# Airbnb ERD

Table users {
  user_id UUID [pk, unique, default: `uuid_generate_v4()`]
  first_name VARCHAR(255) [not null]
  last_name VARCHAR(255) [not null]
  email VARCHAR(255) [not null, unique]
  password_hash VARCHAR(255) [not null]
  phone_number VARCHAR(20)
  role ENUM('guest', 'host', 'admin') [not null, default: 'guest']
  created_at TIMESTAMP [default: `now()`]
}

Table properties {
  property_id UUID [pk, unique, default: `uuid_generate_v4()`]
  host_id UUID [ref: > users.user_id, not null]
  name VARCHAR(255) [not null]
  description TEXT [not null]
  location VARCHAR(255) [not null]
  price_per_night DECIMAL(10, 2) [not null]
  number_of_rooms INT [not null]
  number_of_bathrooms INT [not null]
  max_guests INT [not null]
  amenities TEXT
  created_at TIMESTAMP [default: `now()`]
  updated_at TIMESTAMP [default: `now()`]
}

Table bookings {
  booking_id UUID [pk, unique, default: `uuid_generate_v4()`]
  guest_id UUID [ref: > users.user_id, not null]
  property_id UUID [ref: > properties.property_id, not null]
  check_in_date DATE [not null]
  check_out_date DATE [not null]
  total_price DECIMAL(10, 2) [not null]
  status ENUM('pending', 'confirmed', 'cancelled', 'completed') [not null, default: 'pending']
  created_at TIMESTAMP [default: `now()`]
}

Table reviews {
  review_id UUID [pk, unique, default: `uuid_generate_v4()`]
  booking_id UUID [ref: > bookings.booking_id, not null]
  reviewer_id UUID [ref: > users.user_id, not null]
  property_id UUID [ref: > properties.property_id, not null]
  rating INT [not null]
  comment TEXT
  created_at TIMESTAMP [default: `now()`]
}

Table amenities {
  amenity_id UUID [pk, unique, default: `uuid_generate_v4()`]
  name VARCHAR(255) [not null, unique]
  description TEXT
}

Table property_amenities {
  property_id UUID [ref: > properties.property_id, pk]
  amenity_id UUID [ref: > amenities.amenity_id, pk]
  created_at TIMESTAMP [default: `now()`]
}

// Relationships (DBML automatically infers from 'ref', but explicitly adding them can be clearer)
// Ref: users.user_id < properties.host_id
// Ref: users.user_id < bookings.guest_id
// Ref: properties.property_id < bookings.property_id
// Ref: bookings.booking_id < reviews.booking_id
// Ref: users.user_id < reviews.reviewer_id
// Ref: properties.property_id < reviews.property_id
// Ref: properties.property_id < property_amenities.property_id
// Ref: amenities.amenity_id < property_amenities.amenity_id
