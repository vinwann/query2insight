from tinydb import TinyDB, Query
from datetime import datetime
import os
class TinyDBService:


    def __init__(self, db_file_name=None):
        if db_file_name is None:
            db_file_name = "default_db"
        
        self.db_file = os.path.join("db", f"{db_file_name}.json")
        if not os.path.exists("db"):
            os.makedirs("db")

        self.db = self.connect_or_create_db()
        self.initialize_user_data()
  
        
    def connect_or_create_db(self):
        """Connects to the existing database or creates a new one if it doesn't exist."""
        try:
            if os.path.exists(self.db_file):
                print(f"Connecting to existing database: {self.db_file}")
            else:
                print(f"Creating new database: {self.db_file}")

            db = TinyDB(self.db_file)
            self.metadata_table = db.table("metadata")
            self.api_table = db.table("apidata")
            self.user_data_table = db.table("user_data")
            return db
        except Exception as e:
            print(f"Error connecting to or creating database: {e}")
            return None

    def initialize_user_data(self):
        """Initializes user_data with default structure if empty."""
        if len(self.user_data_table) == 0:
            default_user_data = {
                "name": "",
                "age_years": 0,
                "Gender": "",
                "Height_cm": 0,
                "Weight_kg": 0,
                "Blood_Pressure_mmHg": [],
                "Occupation": "",
                "Alcohol_Intake": "",
                "Physical_Activity_Level": "",
                "Cholesterol_Level_mg_dL": 0,
                "HDL_mg_dL": 0,
                "LDL_mg_dL": 0,
                "Triglycerides_mg_dL": 0,
                "Blood_Glucose_mg_dL": 0,
                "HbA1c_percent": 0
            }
            self.user_data_table.insert(default_user_data)
            print("Initialized user_data with default structure.")


    def insert_data(self, data):
        if not isinstance(data, dict):
            print("Invalid data format. Data must be a dictionary.")
            return False
        
        try:
            self.db.insert(data)
            return True
        except Exception as e:
            print(f"Error inserting data: {e}")
            return False

    def return_chat_history(self):
        try:
            records = self.db.all()
            return records
        except Exception as e:
            print(f"Error retrieving records: {e}")
            return []
    def return_all_chats(self):
        try:
            records = self.db.all()
            return records
        except Exception as e:
            print(f"Error retrieving records: {e}")
            return []
        
    def add_name_by_id(self, id, name):
        """Updates a session's record by adding a name based on the chat ID."""
        try:
            # Search for the record that contains the matching 'id'
            session = Query()
            result = self.db.search(session.id == id)
            
            if not result:
                print(f"No session found with id: {id}")
                return False

            # Assuming you only want to update the first matching record
            record_id = result[0].doc_id  # Get the internal doc_id to update it

            # Update the record with the 'name' field
            self.db.update({'name': name}, doc_ids=[record_id])

            return True
        except Exception as e:
            print(f"Error updating record: {e}")
            return False
        
    def get_element_number_and_total(self, session_id):
        """Returns the session number for the given session id and the total number of elements."""
        try:
            # Get all records
            all_records = self.db.all()

            # Iterate over all records and find the one with the matching session id
            for i, record in enumerate(all_records, start=1):
                if record.get("id") == session_id:
                    # Return the session number (as a string) and the total number of elements
                    return [int(i), len(all_records)]

            # If no match is found, return None and the total number of elements
            return [None, len(all_records)]

        except Exception as e:
            print(f"Error retrieving records: {e}")
            return [None, 0]
    def update_last_updated_time(self, timestamp):
        """Updates the 'last updated time' in the metadata table with a provided timestamp."""
        try:
            # Store the provided timestamp in ISO format in the metadata table
            self.metadata_table.upsert({'key': 'last_updated_time', 'value': timestamp}, Query().key == 'last_updated_time')
        except Exception as e:
            print(f"Error updating last updated time: {e}")

    def get_last_updated_time(self):
        """Retrieves the 'last updated time' from the metadata table."""
        try:
            result = self.metadata_table.get(Query().key == 'last_updated_time')
            if result:
                return result['value']
            else:
                return None
        except Exception as e:
            print(f"Error retrieving last updated time: {e}")
            return None
    
    def update_api_key(self, apiKey):
        try:
            # Store the provided timestamp in ISO format in the metadata table
            self.api_table.upsert({'key': 'api key', 'value': apiKey}, Query().key == 'api key')
        except Exception as e:
            print(f"Error updating api key: {e}")

    def get_api_key(self):
        try:
            result = self.api_table.get(Query().key == 'api key')
            if result:
                return result['value']
            else:
                return None
        except Exception as e:
            print(f"Error retrieving api key: {e}")
            return None
    
    def add_user_data(self, user_data):
        """Inserts user data into the user_data table."""
        try:
            self.user_data_table.insert(user_data)
            return True
        except Exception as e:
            print(f"Error inserting user data: {e}")
            return False

    def update_user_from_string(self, input_str):
        """Updates a specific field in the user data using an input string like 'Height_cm:180' or 'Blood_Pressure_mmHg:180 90'."""
        try:
            # Split the input string by colon
            field, value = input_str.split(":")
            
            # Trim any extra spaces from the field name and value
            field = field.strip()
            value = value.strip()

            # Handle multiple values (e.g., Blood_Pressure_mmHg:180 90)
            if " " in value:
                # Split by spaces and convert each part to int or float
                value_list = [int(v) if v.isdigit() else float(v) for v in value.split()]
                value = value_list  # Store as a list
            else:
                # Handle single value (e.g., Height_cm:180)
                if value.isdigit():
                    value = int(value)
                else:
                    try:
                        value = float(value)
                    except ValueError:
                        # If it's not a number, leave it as a string
                        pass

            result = self.user_data_table.get(doc_id="1")
         
            result[field] = value
            # Update the document in TinyDB
            self.user_data_table.update(result)
            print(f"Updated {field} to {value}.")
            return True
       
        except Exception as e:
            print(f"Error updating user data from string: {e}")
            return False

    def get_user_data(self):
        """Retrieves user data stored under the key '1'."""
        try:
            return self.user_data_table.all()[0]
            
        except Exception as e:
            print(f"Error retrieving user data: {e}")
            return None
        