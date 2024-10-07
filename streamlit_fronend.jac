import:py random;
import:py uuid;
import:py re;
import:py json;
import:py from mtllm.llms, Groq;
import:jac gui;
import:py streamlit as st;
import:py from db_service, TinyDBService;
include:jac rag;

glob chat_meta_db = TinyDBService('meta');

glob api_key = None;

glob llm = None;

glob RagEngine: rag_engine = rag_engine();

glob assitant_type: string = "programming assiatant";

glob current_session_id:str = "";

glob ready_to_chat = False;

enum app_states {
    BOOT_UP = "boot up",
    RUNNING = "running",
    NEW = "new chat"
}

glob app_state = app_states.BOOT_UP;

enum task_type {
    RAG_TYPE: 'Need to use Retrivable information in specific topic' = "RAG",
    QA_TYPE: 'Need to use given user information about themselves or questions asked about themselves' = "user_qa",
    DATA_TYPE: 'Need to use when the user is giving an answer to an question asked by the assistant to update user data' = 'DATA'
}

glob router_examples: 'Examples of routing of a query.if you are uncerteain of the routing method pick task_type.QA_TYPE. Do not pick anything outside of these three options': dict[str, task_type] = {
#'When is my next check up?': task_type.TODO_TYPE,
'whats my name?': task_type.QA_TYPE,
'How to reduce cholrestrole': task_type.RAG_TYPE,
'whats are my tasks for today?': task_type.QA_TYPE,
'Do you think im healthy?': task_type.QA_TYPE,
'What are the symptoms of low blood pressure?': task_type.RAG_TYPE,
'What is a varible in python?': task_type.RAG_TYPE,
'What is programming?': task_type.RAG_TYPE,
'Can you tell me the definition of high blood presure': task_type.RAG_TYPE,
'Im John': task_type.DATA_TYPE,
'25 years old': task_type.DATA_TYPE
};

glob data_examples: 'Examples of the data given by the user and field that you should reply as and the data to be inputted in that field': dict[str, task_type] = {
'My name is john?': "name:John",
'John': "name:John",
'Im 25 years old': "age_years:25",
'My blood pressure is 145 90': "Blood_Pressure_mmHg:145 90",
'John white': "name:john white",
'male': "Gender:male",
'Yes Im married': "Married:True",
'the world is round': "None",
'I cant tell you my weight':"None"
};

glob role_examples: 'Examples for picking assitant role.You are not limited to these examples.if you are uncerteain of the role pick personal assistant': dict[str, str] = {
'Can you help me with programming?': 'Programming assistant',
'Hi help me with this pyhton ?': 'Programming assistant',
'What are the symptoms of low blood pressure?': 'Health assistant',
'Hi?': 'personal assistant',
'Hi who am i?': 'personal assistant'
};

node user {
has user_name: string = "user";
}

walker query {
    has session_id: string = '';
    has just_init: bool = True;
    has inquiry_by_user: string = '';
    has user_query: dict = {"role": '', "content": ''};
    has query_state: int = 0;
    has user_data: 'data about the health status of the user': dict = {};
    has todo_list: 'The tasks to be done by the user in the future.': list = [];
    has session_assitant_type: string = '';
}

'''
Chat session of a user. This node contains the session_id, user_data and todo_list.
This should also include the chat history. Can have multiple chat sessions.
'''
node session {
    has session_id: string = '';
    has chat_history: list = [];
    has chat_file_name: string = 'chat';
    has tinydb_service: obj = '';
    has user_data: dict = {};
    has todo_list: list = [];
    has chat_name: string = "";
    has session_assitant_type: string = '';

    can send_query_to_router with query entry;
    can 'You a smart assitant role picker, using the user query you have to decide what sort of an assitant the user requires to get help.'
    pick_assitant_type(query: 'The question the user has.': str) -> 'response': str by llm(
        temperature=1,
        max_tokens=1024,
        incl_info=(role_examples)
    );
    can 'You a smart assitant that has to pick a name for a chat an user has had. Looking at the chat history suggest a name for the chat and the previous name recommned by you. The name has to be short not more than 5 words and capture the entire conversation'
    chat_name_suggestion(chat_history: 'The chat history': list, chat_name: 'The previous chat name suggested': str) -> 'response': str by llm(temperature=1);
}

'''
Consists of user data such as age, pressure, married status.
'''
node data {
    has user_data: dict = {"age": 0, "Pressure": (0, 0), "Married": False};
}

'''
List of things to do by the user.
'''
node todo {
    has todo_list: list = [];
}

'''
This is the chat walker which will be used to chat with the user.
The create_session ability:
- gather the user data and todo list from connected nodes using filters.
- Creates a new session with the user data and todo list.
- Spawns the chat session with the session id.
'''

# List of things to do by the user.
walker chat {
    has new_chat: bool = True;

    can create_session with user entry;
    can chat_session with session entry;
}

'''
This is where we create the graph.
'''
walker create_graph {
    has user_data: dict = {};
    has todo_list: list = [];

    can generate_graph with `root entry;
}

node router {
    #has match:obj =  re.search(r'(@\w+)\s(.*)', '');
    can direct with query entry;
    can 'route the query to the appropriate task type'
    router_with_llm(query: 'Query from the user to be routed.': str, todo_list: 'The tasks to be done by the user in the future.': list, user_data: 'data about the health status of the user.': dict, chat_history: 'Previous Conversation with the user': list) -> task_type by llm(
        method="Reason",
        temperature=0.0,
        incl_info=(router_examples)
    );
}

node RAG {
    has answer: string = '';

    can print_output with query entry;
    can 'You an Assistant.The type of assistant you are is given in assistant_type use it to give detailed answers. Give a response based on the retrived_context in a detailed manner'
    chat_llm(query: 'Question from the user to be answered.': str, assistant_type: 'The type of assistant you are use this when answering ': str, retrived_context: 'Retrived information from expert articles': list, chat_history: 'Previous Conversation with the user': list) -> 'response': str by llm(temperature=1);
}

node user_QA {
    has answer: string = '';

    can print_output with query entry;
    can 'You are an personal assistant.Answer in friendly detailed manner only answer only questions that are in your domain if you dont know the answer then say that you dont know in a polite manner. IF the user data is empty ask questions about the fields in the user data to get information about the user'
    chat_llm(user_data: 'data about the user': list, query: 'Question from the user to be answered.': str, chat_history: 'Previous Conversation with the user': list) -> 'response': str by llm(temperature=0.7);
}

node user_DATA {
    has answer: string = '';
    has data_entry_answer: string= '';
    can print_output with query entry;
    can 'Using answer given by the user output the field that should be updated in user_data. If there are further empty fields in the user_data ask about them and get answers, if you are uncertain of a field , the user refuses to answer or the answer doesnt make sense return None. Use the exmples given and only reply in that formate'
    data_entry(user_data: 'data about the user': list, answer: 'Data given by the user to be answered.': str, chat_history: 'Previous Conversation with the user': list) -> 'response': str by llm(
        method="Reason",
        temperature=0,
        incl_info=(data_examples)
    );
    can 'You are an personal assistant.The user has answered a question to fill up the user data regarding the user you have to thank the user for answering.The field the answered data belongs to has been determind and given in tfiled variable. IF the user data is empty ask only one question from the empty fields in the user data to get information about the user. Ask from the user'
    chat_llm(user_data: 'data about the user': list, query: 'Answer from the user to be answered.': str,field:'Assied data field for the users answer ':str, chat_history: 'Previous Conversation with the user': list) -> 'response': str by llm(temperature=0.7);
}

node user_TODO {
    has answer: string = '';
    #has assitant_type: string = "programming assiatant";
    has name: 'semstring': str = 'Every reply should be i dont know, thats the only response you can give';
    #'You are a Health Assistant. Give a response based on the query using my todo list.'
    can print_output with query entry;
    can 'Every reply should be i dont know, thats the only response you can give'
    chat_llm(todo_list: 'data about the health status of the user': list, query: 'The tasks to be done by the user in the future.': str, chat_history: 'Previous Conversation with the user': list) -> 'response': str by llm(temperature=0.7, max_tokens=1024);
}

can main() {
    :g: chat_meta_db ;
    
    :g: app_state ;
    
    :g: current_session_id ;
    
    :g: api_key ;
    
    :g: ready_to_chat ;
    
    :g: llm ;
    try 
    {
        feedback_from_gui = gui.start(ready_to_chat);
        if (api_key and feedback_from_gui != "user details") 
        {
            if (type(feedback_from_gui) == bool
                and feedback_from_gui == True) {
                app_state = app_states.NEW;
            } elif (type(feedback_from_gui) == str) {
                if (feedback_from_gui == "new upload") {
                    documents: list = RagEngine.load_documents();
                    chunks: list = RagEngine.split_documents(documents);
                    RagEngine.add_to_chroma(chunks);
                } else {
                    current_session_id = feedback_from_gui;
                }
            }
            if (app_state == app_states.BOOT_UP) {
                os.environ["GROQ_API_KEY"] = api_key;
                llm = Groq(model_name="llama-3.1-70b-versatile");
                create_graph() spawn root;
                chat() spawn [root-->](`?user)[0];
            } elif (app_state == app_states.NEW) {
                chat() spawn [root-->](`?user)[0];
            } else {
                count: int = 0;
                for i in [[root-->](`?user)[0]-->](`?session) {
                    if i.session_id == current_session_id {
                        break;
                    }
                    count += 1;
                }
                query() spawn [[root-->](`?user)[0]-->](`?session)[count];
            }
        } 
        else 
        {
            api_key = chat_meta_db.get_api_key();
            if api_key {
                ready_to_chat = True;
            } else {
                ready_to_chat = False;
            }
        }
    }
    except Exception as e
    {
            print(f"Error: {e}");
    }
    
}
