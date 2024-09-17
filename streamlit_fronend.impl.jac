:node:RAG:can:print_output{
    tinydb_service = TinyDBService('chat'+here.session_id);
    self.answer =self.chat_llm(
            assistant_type=here.session_assitant_type,
            query=here.inquiry_by_user,
            retrived_context=RagEngine.get_from_chroma(query=here.inquiry_by_user),
            chat_history=tinydb_service.return_chat_history()
        );
    gui.display_response(self.answer);
    here.user_query["role"] = "assistant";
    here.user_query["content"] = self.answer;
    here.inquiry_by_user = '';
    visit [<--];
}


:node:user_QA:can:print_output{
    tinydb_service = TinyDBService('chat'+here.session_id);
    #print(tinydb_service.return_chat_history());
    self.answer = self.chat_llm(user_data=here.user_data,
                                query=here.inquiry_by_user,
                                chat_history=tinydb_service.return_chat_history());
    gui.display_response(self.answer);
    here.user_query["role"] = "assistant";
    here.user_query["content"] = self.answer;
    here.inquiry_by_user = '';
    visit [<--];
}
:node:user_TODO:can:print_output{
    tinydb_service = TinyDBService('chat'+here.session_id);
    self.answer = self.chat_llm(todo_list=here.todo_list,query=here.inquiry_by_user,
                                chat_history=tinydb_service.return_chat_history());
    gui.display_response(self.answer);
  
    here.user_query["role"] = "assistant";
    here.user_query["content"] = self.answer;
    here.inquiry_by_user = '';
    visit [<--];
    
}
:node:session:can:send_query_to_router{

    if (here.just_init){
        here.just_init = False;
        gui.chat_interface(here,self);
        here.session_id = self.session_id;
        here.user_data =self.user_data;
        here.todo_list = self.todo_list;
        here.chat_history = [];

        if (len(here.inquiry_by_user) > 0 )
        {
            self.session_assitant_type = self.pick_assitant_type(here.inquiry_by_user);
            print(self.session_assitant_type);
            here.session_assitant_type = self.session_assitant_type;
        }
            
        
    }
    if (here.query_state == 0)
    {
     
        if (len(here.inquiry_by_user) > 0)
        {
            self.chat_history.append({"role":"user","content" : here.inquiry_by_user});
            self.tinydb_service.insert_data({"role":"user","content" : here.inquiry_by_user});
            visit [-->];   
        } 
        here.query_state  = 1;
    }
    elif (here.query_state == 1){
        self.chat_history.append(here.user_query);
        self.tinydb_service.insert_data(here.user_query);
        here.query_state  = 2;
    } 
    
}

:node:router:can:direct{
    if (len(here.inquiry_by_user)>0)
    {
        task:task_type = self.router_with_llm(query = here.inquiry_by_user, todo_list = here.todo_list, user_data = here.user_data);
        print(task);
        if task == task_type.RAG_TYPE {
            visit [-->](`?RAG);
        }  elif task == task_type.QA_TYPE | task != None {
            visit [-->](`?user_QA);
        }   
        else
        {
            gui.display_response("Kindly add a routing method by using @ in the start of your question\nTo visit TODO : @TODO\nTo visit RAG : @RAG\nTo visit QA : @QA");
            here.user_query["role"] = "assistant";
            here.user_query["content"] = "Kindly add a routing method by using @ in the start of your question\nTo visit TODO : @TODO\nTo visit RAG : @RAG\nTo visit QA : @QA";
            here.inquiry_by_user = '';
            here.query_state = True;
            visit [<--];
        }
    }
    else{
        #here.query_state = 1;
        visit [<--];
    }    
}

:walker:create_graph:can:generate_graph{

    end = here; # Assign the current root node (here) to end
    end ++> (end := user()); # Create a user node and connect it to the end node. Assign the new user node to the end.
    end ++> data(user_data = self.user_data); # Create a data node with the user data and connect it to the end node.
    end ++> todo(todo_list = self.todo_list); # Create a todo node with the todo list and connect it to the end node.
}

:walker:chat:can:create_session{
    :g: chat_meta_db;
    if (self.new_chat)
    {
        # Telescope into the nodes connected to the user node without walking.
        data_node = [-->](`?data)[0]; # Getting the data node filtered. can use [0] as having only one such node.
        todo_node = [-->](`?todo)[0]; # Getting the todo node filtered. can use [0] as having only one such node.
        new_session_id = str(uuid.uuid4());
        # Creating a new session node with the user data and todo list and connect it to the user.
        n = here ++> session(   session_id = new_session_id,
                            user_data = data_node.user_data,
                            todo_list = todo_node.todo_list,
                            tinydb_service = TinyDBService('chat'+new_session_id)
                        );
        chat_meta_db.insert_data({"id":'chat'+new_session_id});
        visit n;

    }
}
:walker:chat:can:chat_session{

        query() spawn here;
        self.new_chat =False;
        end = here;
        end ++> (end := router());
        end ++> RAG();
        end ++> user_QA();
        end ++> user_TODO();
        visit[<--];
        
}

