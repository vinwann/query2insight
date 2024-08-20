import:py random;
import:py uuid;
import:py re;
import:py json;
import:py from mtllm.llms, Groq;
import:jac gui;
import:py streamlit as st;
import:py from db_service,TinyDBService;
include:jac rag;

glob chat_meta_db = TinyDBService('meta');
glob llm = Groq(model_name = "llama3-8b-8192");
glob state = 0;
glob RagEngine:rag_engine = rag_engine();

enum task_type {
    RAG_TYPE : 'Need to use Retrivable information in specific medical articles' = "RAG",
    QA_TYPE : 'Need to use given user information about themselves' = "user_qa",
    TODO_TYPE : 'Need to use the todo list of the user' = "todo"
}
glob router_examples: 'Examples of routing of a query': dict[str, task_type] = {
    'When is my next check up?': task_type.TODO_TYPE,
    'How healthy am I?': task_type.QA_TYPE,
    'What are the symptoms of low blood pressure?': task_type.RAG_TYPE
};
can main() {
    
    :g: state;
    
    if (gui.start()){
        state = 1;   
    }
    
    if (state == 0)
    {
    create_graph(   user_data={ "age": 20,
                                    "Pressure": (120, 80),
                                    "Married": False
                                },
                        todo_list=["Do heart surgery",
                                    "Buy Bread",
                                    "Have pizza for dinner"]
                    ) spawn root;
        state = 2;
        chat() spawn [root-->](`?user)[0];
    }
    elif(state == 1)
    {
        chat() spawn [root-->](`?user)[0];
        state = 2;
    }
    else{
        query() spawn [[root -->](`?user)[0] -->](`?session)[-1];
        
        
    }
}



node user{
    has user_name:string="user";
}

walker query {
    #can go_to_router with session entry;
    has session_id : string =  '';
    has just_init :bool = True;
    has inquiry_by_user: string = '';
    has user_query : dict={"role":'',
                            "content":''}; 
    has query_state:int = 0;
    has user_data: 'data about the health status of the user' :dict={};
    has todo_list: 'The tasks to be done by the user in the future.' :list=[];


}
'''
Chat session of a user. This node contains the session_id, user_data and todo_list.
This should also include the chat history. Can have multiple chat sessions.
'''
node session{
    has session_id : string = '';
    has chat_history : list = [];
    has chat_file_name:string = 'chat';
    has tinydb_service:obj ='';
    has user_data : dict = {}; # User data such as habits, heart rate etc.
    has todo_list : list = []; # List of things to do by the user.
    can send_query_to_router with query entry;
}


'''
Consists of user data such as age, pressure, married status.
'''
node data{
    has user_data:dict = {
                "age" : 0,
                "Pressure" : (0,0),
                "Married" : False
                };
}

'''
List of things to do by the user.
'''
node todo{
    
    has todo_list:list = [];
}

'''
This is the chat walker which will be used to chat with the user.
The create_session ability:
    - gather the user data and todo list from connected nodes using filters.
    - Creates a new session with the user data and todo list.
    - Spawns the chat session with the session id.
'''
walker chat{
    has new_chat : bool = True;
    can create_session with user entry;
    can chat_session with session entry;
}
'''
This is where we create the graph.
'''
walker create_graph{
    has user_data:dict = {};
    has todo_list:list = [];
    can generate_graph with `root entry;
}

node router {
    #has match:obj =  re.search(r'(@\w+)\s(.*)', '');
    can direct with query entry;
     can 'route the query to the appropriate task type'
    router_with_llm(query:'Query from the user to be routed.':str,
                    todo_list:'The tasks to be done by the user in the future.':list,
                    user_data:'data about the health status of the user.':dict) -> task_type
                                        by llm(method="Reason", temperature=0.0, incl_info=(router_examples));
}
node RAG {
    has answer:string = '';
    can print_output with query entry;
    can 'You are a warmly Health Assistant named JacCare. Give a response based on the query using todo list. and user data'
    chat_llm(todo_list:'The tasks to be done by the user in the future.':list,
             user_data:'data about the health status of the user.':dict,
             query:'Question from the user to be answered.':str,
             retrived_context : 'Retrived information from expert articles':list) -> 'response':str by llm(temperature =0.8);
}
node user_QA{
    has answer:string = '';
    can print_output with query entry;
    can 'You are a personal Assistant. Give a response based on the query using my todo list.'
    chat_llm(user_data:'data about the user':list,
             query:'The question the user has.':str) -> 'response':str by llm(temperature=0.7, max_tokens=1024);
}
node user_TODO{
    has answer:string = '';
    can print_output with query entry;
    can 'You are a Health Assistant. Give a response based on the query using my todo list.'
    chat_llm(todo_list:'data about the health status of the user':list,
             query:'The tasks to be done by the user in the future.':str) -> 'response':str by llm(temperature=0.7, max_tokens=1024);
}


    
