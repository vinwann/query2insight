:node:RAG:can:print_output {
    tinydb_service = TinyDBService(here.session_id);
    self.answer = self.chat_llm(
        assistant_type=here.session_assitant_type,
        query=here.inquiry_by_user,
        retrived_context=RagEngine.get_from_chroma(query=here.inquiry_by_user),
        chat_history=tinydb_service.return_chat_history()
    );
    matches = re.findall(r'"([^"]*)"', self.answer);
    print("matches ", matches);
    if len(matches) > 0 {
        self.answer = matches[0];
    }
    gui.display_response(self.answer);
    here.user_query["role"] = "assistant";
    here.user_query["content"] = self.answer;
    here.inquiry_by_user = '';
    visit [<--];
}

:node:user_QA:can:print_output {
    tinydb_service = TinyDBService(here.session_id);
    self.answer = self.chat_llm(
        user_data=here.user_data,
        query=here.inquiry_by_user,
        chat_history=tinydb_service.return_chat_history()
    );
    matches = re.findall(r'"([^"]*)"', self.answer);
    print("matches ", matches);
    if len(matches) > 0 {
        self.answer = matches[0];
    }
    gui.display_response(self.answer);
    here.user_query["role"] = "assistant";
    here.user_query["content"] = self.answer;
    here.inquiry_by_user = '';
    visit [<--];
}

:node:user_TODO:can:print_output {
    tinydb_service = TinyDBService(here.session_id);
    self.answer = self.chat_llm(
        todo_list=here.todo_list,
        query=here.inquiry_by_user,
        chat_history=tinydb_service.return_chat_history()
    );
    matches = re.findall(r'"([^"]*)"', self.answer);
    print("matches ", matches);
    if len(matches) > 0 {
        self.answer = matches[0];
    }
    gui.display_response(self.answer);
    here.user_query["role"] = "assistant";
    here.user_query["content"] = self.answer;
    here.inquiry_by_user = '';
    visit [<--];
}

:node:session:can:send_query_to_router {
    :g: chat_meta_db ;
    
    print("session_id ", self.session_id);
    if (here.just_init) {
        here.just_init = False;
        gui.chat_interface(here, self);
        here.session_id = self.session_id;
        here.user_data = self.user_data;
        here.todo_list = self.todo_list;
        here.chat_history = [];
        if (len(here.inquiry_by_user) > 0) {
            self.session_assitant_type = self.pick_assitant_type(here.inquiry_by_user);
            matches = re.findall(r'"([^"]*)"', self.session_assitant_type);
            print("matches ", matches);
            if len(matches) > 0 {
                self.session_assitant_type = matches[0];
            }
            print(self.session_assitant_type);
            here.session_assitant_type = self.session_assitant_type;
        }
    }
    if (here.query_state == 0) {
        if (len(here.inquiry_by_user) > 0) {
            self.chat_history.append(
                {"role": "user", "content": here.inquiry_by_user}
            );
            self.tinydb_service.insert_data(
                {"role": "user", "content": here.inquiry_by_user}
            );
            visit [-->];
        }
        here.query_state = 1;
    } elif (here.query_state == 1) {
        self.chat_history.append(here.user_query);
        self.tinydb_service.insert_data(here.user_query);
        self.chat_name = self.chat_name_suggestion(
            chat_history=self.tinydb_service.return_chat_history(),
            chat_name=self.chat_name
        );
        matches = re.findall(r'"([^"]*)"', self.chat_name);
        print("matches ", matches);
        if len(matches) > 0 {
            self.chat_name = matches[0];
        }
        chat_meta_db.add_name_by_id(
            self.session_id,
            self.chat_name
        );
        here.query_state = 2;
    }
}

:node:router:can:direct {
    if (len(here.inquiry_by_user) > 0) {
        task: task_type = self.router_with_llm(
            query=here.inquiry_by_user,
            todo_list=here.todo_list,
            user_data=here.user_data
        );
        print(task);
        if task == task_type.RAG_TYPE {
            visit [-->](`?RAG);
        } elif task == task_type.QA_TYPE | task != None {
            visit [-->](`?user_QA);
        } else {
            gui.display_response(
                "Kindly add a routing method by using @ in the start of your question\nTo visit TODO : @TODO\nTo visit RAG : @RAG\nTo visit QA : @QA"
            );
            here.user_query["role"] = "assistant";
            here.user_query["content"] = "Kindly add a routing method by using @ in the start of your question\nTo visit TODO : @TODO\nTo visit RAG : @RAG\nTo visit QA : @QA";
            here.inquiry_by_user = '';
            here.query_state = True;
            visit [<--];
        }
    } else {
        #here.query_state = 1;
        visit [<--];
    }
}

:walker:create_graph:can:generate_graph {
    end = here;# Assign the current root node (here) to end
    end ++> (end := user()); # Create a user node and connect it to the end node. Assign the new user node to the end.
    end ++> data(user_data=self.user_data); # Create a data node with the user data and connect it to the end node.
    end ++> todo(todo_list=self.todo_list); # Create a todo node with the todo list and connect it to the end node.
}

:walker:chat:can:create_session {
    :g: chat_meta_db ;
    
    :g: app_state ;
    
    :g: current_session_id ;
    
    data_node = [-->](`?data)[0];# Getting the data node filtered. can use [0] as having only one such node.
    todo_node = [-->](`?todo)[0];# Getting the todo node filtered. can use [0] as having only one such node.
    if (app_state == app_states.BOOT_UP) {
        for chat_id in chat_meta_db.return_all_chats() {
            temp_tinydb_service: obj = TinyDBService(chat_id['id']);
            session_node = here ++> session(
                session_id=chat_id['id'],
                user_data=data_node.user_data,
                todo_list=todo_node.todo_list,
                tinydb_service=TinyDBService(chat_id['id']),
                chat_history=temp_tinydb_service.return_chat_history()
            );
            end = session_node;
            end ++> (end := router());
            end ++> RAG();
            end ++> user_QA();
            end ++> user_TODO();
        }
        app_state = app_states.RUNNING;
    } elif (app_state == app_states.NEW) {
        # Telescope into the nodes connected to the user node without walking.
        new_session_id = str(uuid.uuid4());
        n = here ++> session(
            session_id=new_session_id,
            user_data=data_node.user_data,
            todo_list=todo_node.todo_list,
            tinydb_service=TinyDBService(new_session_id)
        );
        chat_meta_db.insert_data(
            {"id": new_session_id, "name": "New chat"}
        );
        app_state = app_states.RUNNING;
        current_session_id = new_session_id;
        visit n;
    }
}

:walker:chat:can:chat_session {
    query() spawn here;
    self.new_chat = False;
    end = here;
    end ++> (end := router());
    end ++> RAG();
    end ++> user_QA();
    end ++> user_TODO();
    visit [<--];
}
