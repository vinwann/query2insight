from tinydb import TinyDB
from tinydb import Query
import os

class TinyDBService:
    def __init__(self, db_file_name=None):
        if db_file_name is None:
            db_file_name = "default_db"
        
        self.db_file = os.path.join("db", f"{db_file_name}.json")
        if not os.path.exists("db"):
            os.makedirs("db")

        self.db = self.create_db()

    def create_db(self):
        """Creates and returns a TinyDB instance."""
        try:
            db = TinyDB(self.db_file)
            return db
        except Exception as e:
            print(f"Error creating database: {e}")
            return None

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
