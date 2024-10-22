import os
import time
from datetime import datetime
from dbService import TinyDBService

class FileUpdateChecker:
    def __init__(self, folder_name):
        self.folder_path = os.path.join(os.getcwd(), folder_name)
        if not os.path.exists(self.folder_path):
            os.makedirs(self.folder_path)
        self.dbService = TinyDBService('meta')    
        last_updated_time_str = self.dbService.get_last_updated_time()
        if last_updated_time_str:
            try:
             
                self.last_checked = datetime.fromisoformat(last_updated_time_str).timestamp()
            except ValueError:
                print(f"Error parsing last updated time: {last_updated_time_str}")
    
                self.last_checked = None
                #self.dbService.update_last_updated_time(datetime.fromtimestamp(self.last_checked).isoformat())
        else:
            # If no last updated time exists, set the current time and update the database
            self.last_checked = None
            #self.dbService.update_last_updated_time(datetime.fromtimestamp(self.last_checked).isoformat())

        # Get the initial file modification times
        self.file_mod_times = self.get_file_mod_times()
        

    def get_file_mod_times(self):
        """Retrieve the modification times of all files in the folder."""
        file_mod_times = {}
        for root, _, files in os.walk(self.folder_path):
            for file in files:
                file_path = os.path.join(root, file)
                if os.path.isfile(file_path):
                    file_mod_times[file_path] = os.path.getmtime(file_path)
        return file_mod_times

    def has_updated_files(self):
        """Check if any file has been updated since the last update."""
        if self.last_checked == None:
            self.last_checked = time.time()
            self.dbService.update_last_updated_time(datetime.fromtimestamp(self.last_checked).isoformat())
            return True
        current_mod_times = self.get_file_mod_times()
        for file_path, mod_time in current_mod_times.items():
            # Check if the file was modified after the last checked time
            if file_path not in self.file_mod_times or mod_time > self.last_checked:
                self.last_checked = time.time()  # Update last checked time

                # Persist the last checked time in the database
                self.dbService.update_last_updated_time(datetime.fromtimestamp(self.last_checked).isoformat())

                self.file_mod_times = current_mod_times
                return True
        return False