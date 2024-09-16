
## CarPool Project

The CarPool project is a ride-sharing application aimed at assisting **drivers** in finding shared rides to work or university. The app allows drivers to create and join ride groups based on various criteria.


## Features

- **User Registration & Login:** Users can sign up and log in. Every user is a **driver** in the system.


- **Driver Profile:** Each driver is characterized by their name, address, and phone number.
   Additionally, each user can modify the number of seats available in their vehicle.


- **Create a Ride Group:**
    
    - Drivers can create a new ride group.
    - Ride groups are defined by the group creator, starting point, available seats, schedule (days and times), a map, and group participants.
    - Each participant's points in the group are tracked.
- **Search for Ride Groups:**
    - Drivers can search for existing ride groups by start point, schedule, or group creator’s name.
   - If a user joins a group, their points in that group start at zero.

- **Group Capacity:** 
    - Once a ride group reaches the maximum number of participants (based on available seats), it is marked as full and closed for further joining.
    - If a driver’s vehicle has fewer seats than the group requires, they cannot join the group.
- **Group Management:**
    - Once a group is created, the creator cannot modify or delete the group, but they may leave the group without it being deleted.
    - If a group has zero participants, it will be automatically deleted.
- **Ride Day Calculation:**
    - The group page shows all group details and calculates the driver with the lowest points to be the driver for the day.
    - The designated driver will have a button to "Start Ride" which will change to "End Ride".
    - After ending the ride, the driver receives one point for that day’s ride.
- **Next Day Driver:**
    - The system calculates the next driver based on the lowest points. If multiple drivers have the same points, the system will randomly assign the next driver.
- **Pickup Points:**
    - Each ride group has three predefined pickup points selected by the group creator.
    - Each participant can choose their fixed pickup point from these three options.
- **Notifications:**
  
   The system provides various alerts to keep users informed about ride activities. These include:
    - Group Creation Alert: A notification is sent when a new group is created.
    - User Joined Group Alert: A notification is sent when a new user joins the ride group.
    - User Left Group Alert: A notification is sent when a user leaves the ride group.
    - Pickup Point Change Alert: A notification is sent when a user changes their pickup point.
    - Ride Start Alert: A notification is sent when the ride starts.
    - Ride End Alert: A notification is sent when the ride ends.
    - Point Received Alert: A notification is sent when a driver receives a point for completing a ride.

## Technologies Used
- **Dart:** The main programming language.
- **Flutter:** The framework used for building the mobile app.
- **OpenStreetMap:** Integrated for map functionality, allowing users to view the pickup points on an interactive map.
- **VS Code:** The development environment.
  
## Video Demonstration





https://github.com/user-attachments/assets/1a2b332e-0320-46f7-bdd3-764e7522d415

