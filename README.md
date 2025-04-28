# Flight Tracking System

## I. App Setup Instructions 

1. **Install MySQL**
   - Can do so using the following command in terminal for MacOS users
     ```
     brew install mysql
     ```
  
2. **Create and Initialize the Database**
   - To create and initialize the database, open a terminal window where the files are located
   - Then run the following commands
   
      ```
      mysql -u root -p < cs4400_sams_phase3_database_v0.sql
      mysql -u root -p flight_tracking < cs4400_sams_phase3_mechanics_TEMPLATE_v0.sql
      ```
## II. Instructions to Run GUI Application

1. **Run the Python File**
   - Make sure that the python file is in the same folder as the other SQL files mentioned above
   - In a terminal window in that folder, run the following command
     ```
     python FlightGUI.py
     ```
2. **Interacting with GUI Application
   - Now, you can see the GUI where the user can interact with it now.
   - There are two dropdowns.
        - One asks the user to 'Select procedure/view'
   - Once the user has selected that, there is a type-in box that asks the user the paramters for the procedure or view they selected from the first drop down.
  
3. **Resetting the GUI Application
   - Once the user is done using the GUI application, they can..
     1. Close out the application
     2. Run the commands from step 2 again to reset the databases to the way they were

## Technologies/Tools Used 

1. MySQL
2. Python
3. Tinker
