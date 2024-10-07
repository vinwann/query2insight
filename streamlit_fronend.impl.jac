:node:RAG:can:print_output {
    # Create a TinyDB service instance to fetch data for the current chat session from the database
    tinydb_service = TinyDBService(here.session_id);
    
    # Fetch the response from the LLM by passing the session assistant type, user query, and retrieved context using the RAG engine
    self.answer = self.chat_llm(
        assistant_type=here.session_assitant_type,  # Type of assistant (e.g., programming assistant)
        query=here.inquiry_by_user,  # The question asked by the user
        retrived_context=RagEngine.get_from_chroma(query=here.inquiry_by_user),  # Retrieve context from ChromaDB
        chat_history=tinydb_service.return_chat_history()  # Fetch chat history from the database
    );
    
    # Extract only relevant information from the LLM's response by finding parts within quotes
    matches = re.findall(r'"([^"]*)"', self.answer);
    if len(matches) > 0 {
        self.answer = matches[0];  # If relevant parts exist, use the first one
    }
    
    # Print the extracted match for debugging purposes
    print(matches);
    
    # Display the cleaned answer in the GUI
    gui.display_response(self.answer);
    
    # Update the user query with the assistant's response
    here.user_query["role"] = "assistant";
    here.user_query["content"] = self.answer;
    
    # Clear the user's inquiry after processing
    here.inquiry_by_user = '';
    
    # Return to the previous node in the workflow
    visit [<--];
}

:node:user_QA:can:print_output {
    # Fetch the TinyDB service instance for the current session
    tinydb_service = TinyDBService(here.session_id);
    
    # Call the LLM to get a response based on user data and inquiry
    self.answer = self.chat_llm(
        user_data=here.user_data,  # User-specific data stored in the session
        query=here.inquiry_by_user,  # The question asked by the user
        chat_history=tinydb_service.return_chat_history()  # Fetch chat history from the database
    );
    
    # Extract relevant portions of the LLM's response
    matches = re.findall(r'"([^"]*)"', self.answer);
    if len(matches) > 0 {
        self.answer = matches[0];
    }
    
    # Print the extracted match for debugging purposes
    print(matches);
    
    # Display the processed answer in the GUI
    gui.display_response(self.answer);
    
    # Update the user query with the assistant's response
    here.user_query["role"] = "assistant";
    here.user_query["content"] = self.answer;
    
    # Clear the user's inquiry after processing
    here.inquiry_by_user = '';
    
    # Return to the previous node in the workflow
    visit [<--];
}

:node:user_DATA:can:print_output {
    # Fetch the TinyDB service instance for the current session
    tinydb_service = TinyDBService(here.session_id);
    
    # Call the LLM to determine which field in the user data needs updating and with what value
    self.data_entry_answer = self.data_entry(
        user_data=here.user_data,  # The user's existing data
        answer=here.inquiry_by_user,  # The user's input to update the data
        chat_history=tinydb_service.return_chat_history()  # Fetch chat history
    );
    
    # Print the data entry answer for debugging purposes
    print(self.data_entry_answer);
    
    # If valid data fields are returned, update the database with new user information
    if (self.data_entry_answer and self.data_entry_answer != "None") {
        for i in self.data_entry_answer {
            if i != "None" {
                chat_meta_db.update_user_from_string(i);  # Update the user data in the database
            }
        }
    }
    
    # Call the LLM to provide a response after updating user data
    self.answer = self.chat_llm(
        user_data=here.user_data,  # Updated user data
        query=here.inquiry_by_user,  # User's input query
        field=self.data_entry_answer,  # Fields that were updated
        chat_history=tinydb_service.return_chat_history()  # Fetch chat history
    );
    
    # Extract relevant portions of the LLM's response
    matches = re.findall(r'"([^"]*)"', self.answer);
    if len(matches) > 0 {
        self.answer = matches[0];
    }
    
    # Print the extracted match for debugging purposes
    print(matches);
    
    # Display the processed answer in the GUI
    gui.display_response(self.answer);
    
    # Update the user query with the assistant's response
    here.user_query["role"] = "assistant";
    here.user_query["content"] = self.answer;
    
    # Clear the user's inquiry after processing
    here.inquiry_by_user = '';
    
    # Return to the previous node in the workflow
    visit [<--];
}

:node:session:can:send_query_to_router {
    :g: chat_meta_db ;
    
    # On initial chat setup, fetch necessary details, like session ID and user data
    if (here.just_init) {
        here.just_init = False;
        gui.chat_interface(here, self);  # Initiate the GUI with session information
        here.session_id = self.session_id;  # Assign the current session ID
        self.user_data = chat_meta_db.get_user_data();  # Retrieve user data from the database
        here.user_data = self.user_data;
        here.chat_history = [];
        
        # If there is a user inquiry, determine the assistant type based on the inquiry
        if (len(here.inquiry_by_user) > 0) {
            self.session_assitant_type = self.pick_assitant_type(here.inquiry_by_user);
            matches = re.findall(r'"([^"]*)"', self.session_assitant_type);
            if len(matches) > 0 {
                self.session_assitant_type = matches[0];
            }
            print("Selected assistant type ",self.session_assitant_type);
            here.session_assitant_type = self.session_assitant_type;
        }
    }
    
    # If this is the first state, proceed with adding user inquiry to chat history and database
    if (here.query_state == 0) {
        if (len(here.inquiry_by_user) > 0) {
            self.chat_history.append({"role": "user", "content": here.inquiry_by_user});
            self.tinydb_service.insert_data({"role": "user", "content": here.inquiry_by_user});  # Save inquiry to the database
            visit [-->];  # Move to next node in the workflow
        }
        here.query_state = 1;
    } 
    # Add assistant response to chat history and suggest a chat name
    elif (here.query_state == 1) {
        self.chat_history.append(here.user_query);
        self.tinydb_service.insert_data(here.user_query);  # Save assistant's response to the database
        self.chat_name = self.chat_name_suggestion(
            chat_history=self.tinydb_service.return_chat_history(),
            chat_name=self.chat_name
        );
        matches = re.findall(r'"([^"]*)"', self.chat_name);
        if len(matches) > 0 {
            self.chat_name = matches[0];
        }
        chat_meta_db.add_name_by_id(self.session_id, self.chat_name);  # Update the chat name in the database
        here.query_state = 2;
    }
}

:node:router:can:direct {
    # Direct user queries to appropriate tasks (RAG, QA, or DATA)
    if (len(here.inquiry_by_user) > 0) {
        tinydb_service = TinyDBService(here.session_id);  # Create a TinyDB service for the current session
        task: task_type = self.router_with_llm(
            query=here.inquiry_by_user,  # User's query
            user_data=here.user_data,  # Data about the user
            chat_history=tinydb_service.return_chat_history()  # Fetch chat history
        );
        print("Task type ",task);
        
        # Depending on the task type, visit corresponding nodes
        if task == task_type.RAG_TYPE {
            visit [-->](`?RAG);
        } elif task == task_type.QA_TYPE {
            visit [-->](`?user_QA);
        } elif task == task_type.DATA_TYPE {
            visit [-->](`?user_DATA);
        } else {
            # If no valid routing is provided, prompt the user for a routing method
            gui.display_response("Kindly add a routing method by using @ in the start of your question\nTo visit TODO : @TODO\nTo visit RAG : @RAG\nTo visit QA : @QA");
            here.user_query["role"] = "assistant";
            here.user_query["content"] = "Kindly add a routing method by using @ in the start of your question\nTo visit TODO : @TODO\nTo visit RAG : @RAG\nTo visit QA : @QA";
            here.inquiry_by_user = '';
            here.query_state = True;
            visit [<--];  # Return to the previous node
        }
    } else {
        visit [<--];  # No inquiry, just return to the previous node
    }
}

:walker:create_graph:can:generate_graph {
    # Start creating the chat session graph
    end = here;  # Root node (start of the graph)
    end ++> (end := user());  # Create a user node and connect it to the root node
}

:walker:chat:can:create_session {
    :g: chat_meta_db ;
    :g: app_state ;
    :g: current_session_id ;
    
    # If the app is in boot-up state, load all existing chat sessions from the database
    if (app_state == app_states.BOOT_UP) {
        for chat_id in chat_meta_db.return_all_chats() {
            temp_tinydb_service: obj = TinyDBService(chat_id['id']);
            session_node = here ++> session(
                session_id=chat_id['id'],
                user_data= chat_meta_db.get_user_data(),
                tinydb_service=TinyDBService(chat_id['id']),
                chat_history=temp_tinydb_service.return_chat_history()
            );
            end = session_node;
            end ++> (end := router());  # Connect router node to session
            end ++> RAG();  # Connect RAG node
            end ++> user_QA();  # Connect QA node
            end ++> user_DATA();  # Connect DATA node
        }
        app_state = app_states.RUNNING;  # Set app state to running
    } 
    # Create a new chat session if the app is in new chat state
    elif (app_state == app_states.NEW) {
        new_session_id = str(uuid.uuid4());  # Generate a new unique session ID
        n = here ++> session(
            session_id=new_session_id,
            user_data= chat_meta_db.get_user_data(),
            tinydb_service=TinyDBService(new_session_id)
        );
        chat_meta_db.insert_data({"id": new_session_id, "name": "New chat"});  # Save the new session to the database
        app_state = app_states.RUNNING;  # Update app state
        current_session_id = new_session_id;  # Set the current session ID
        visit n;  # Visit the new session node
    }
}

:walker:chat:can:chat_session {
    query() spawn here;  # Create a new query walker for the session
    self.new_chat = False;  # Mark this as an existing chat
    end = here;
    end ++> (end := router());  # Connect the router node
    end ++> RAG();  # Connect RAG node
    end ++> user_QA();  # Connect QA node
    end ++> user_DATA();  # Connect DATA node
    visit [<--];  # Return to the previous node
}
