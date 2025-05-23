# Flight Tracking System

## I. App Setup Instructions 

1. **Install MySQL**
   - Can do so using the following command in terminal for MacOS users
     ```
     brew install mysql
     ```
   - Make sure you can run MySQL by running the following command
     ```
     brew services start mysql
     ```
     
2. **Create and Initialize the Database**
   - To create and initialize the database, open a terminal window where the files are located
   - Then run the following commands
   
      ```
      mysql -u root -p < cs4400_sams_phase3_database_v0.sql
      mysql -u root -p flight_tracking < cs4400_sams_phase3_mechanics_TEMPLATE_v0.sql
      ```
   - Everytime the user runs these commands in the terminal, the terminal will ask the user for a password. The user must enter the password that they use to log into SQL Workbench.
## II. Instructions to Run GUI Application

1. **Run the Python File**
   - Make sure that the python file is in the same folder as the other SQL files mentioned above
   - Before you run python file, you must change a line at the top of the file. There will be a line that says :
     ```
     DB_PASSWORD = 'password'
     ```
   - Where it says password, the user must replace it with their own password from SQL Workbench.
   - The user must do this, so when they apply changes in the GUI, those changes will be seen in the database.
   - In a terminal window in that folder, run the following command
     ```
     python FlightGUI.py
     ```
2. **Interacting with GUI Application**
   - ![Flight Tracker GUI](GUI.png)
   - Now, you can see the GUI where the user can interact with it now.
   - There are two user inputs
        - One asks the user to 'Select procedure/view'
        - Once the user has selected that, there is a type-in box that asks the user the paramters for the procedure or view they selected from the first drop down.
  
4. **Resetting the GUI Application**
   - Once the user is done using the GUI application, they can..
     1. Close out the application
     2. Run the commands from Step 2 of Part I again to reset the databases to the way they were

## III. Technologies/Tools Used 

 ```MySQL```
  - MySQL serves as the relational datbase for this project. All of the data is held here plus the logic. By logic, I am referring to the stored procedures and views meaning this all runs on the server side. This way when a user interacts with the GUI, that command is then relayed to Python which relays back signals to MySQL to execute those commands from the user whether it be executing procedures or viewing data.

```Python```
   - Python serves as the middle man between MySQL and Tkinter (which will be explained later), connected by ``` mysql.connector ```. Essentially, Python controls the flow of user input into the GUI. It takes all of the user input, data handles, checks for errors, and then transforms the SQL data into Python methods, so now the user can interact with the stored procedures and views without having to write SQL queries. This allows for the backend to be more accessible from the GUI.

```Tkinter```
   - Tkinter is a Python GUI toolkit that we used to make this interface as it does not require any additionl functional dependencies. Tkinter provides all the user interface, and what esentially happens is that user actions are driven through an event loop. This event loop exists, so that user input is then relayed to Python callback methods which then goes and interacts with MySQL. After the wrapped up Python code interacts with MySQL, that information is then relayed all the way back to the GUI where the users can see real time results due to this interactive frontend and keep making changes, adjustments, or even just view database structure/logic without having to write SQL queries.

## IV. Contributions from Group Members
- Shriyan
     - Helped update the stored procedures to ensure everything worked accurately
     - Tested portions of the GUI and updated it to ensure it worked as expected
     - Wrote some of the ReadMe file discussing how to access the GUI
- Sanvi 
   - Tested portions of the GUI to verify it's functionality for different use cases
   - Helped update and improve the UI components by refining the design and layout to make it more visually appealing
- Soham
  - Assisted in the development of the GUI, focusing on improving the user interface
  - Collaborated on the integration of MySQL with Python, ensuring seamless interaction between the backend and frontend 
- Rishit
   - Wrote portions of the ReadMe file, explaining the technologies behind the UI as well how to interact with the GUI
   - Tested portions of the GUI to test the functionality
