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

glob llm = Groq(model_name="llama-3.1-70b-versatile");

glob state = 0;

glob RagEngine: rag_engine = rag_engine();

glob assitant_type: string = "programming assiatant";

can main() {
    :g: state ;
    
    if (gui.start()) {
        state = 1;
    }
    if (state == 0) {
        with open('user_info.json', 'r') as f {
            imported_data = json.load(f);
        }
        create_graph(
            user_data=imported_data['user_data'],
            todo_list=imported_data['todo_list']
        ) spawn root;
        state = 2;
        chat() spawn [root-->](`?user)[0];
    } elif (state == 1) {
        chat() spawn [root-->](`?user)[0];
        state = 2;
    } else {
        query() spawn [[root-->](`?user)[0]-->](`?session)[-1];
    }
}

enum task_type {
    RAG_TYPE: 'Need to use Retrivable information in specific topic' = "RAG",
    QA_TYPE: 'Need to use given user information about themselves or questions asked about themselves' = "user_qa"
}

glob router_examples: 'Examples of routing of a query.if you are uncerteain of the routing method pick task_type.QA_TYPE. Do not pick anything outside of these three options': dict[str, task_type] = {
#'When is my next check up?': task_type.TODO_TYPE,
'whats my name?': task_type.QA_TYPE,'How to reduce cholrestrole': task_type.RAG_TYPE,'whats are my tasks for today?': task_type.QA_TYPE,'Do you think im healthy?': task_type.QA_TYPE,'What are the symptoms of low blood pressure?': task_type.RAG_TYPE,'What is a varible in python?': task_type.RAG_TYPE,'What is programming?': task_type.RAG_TYPE,'Can you tell me the definition of high blood presure': task_type.RAG_TYPE
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
    #can go_to_router with session entry;
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
    has user_data: dict = {}; # User data such as habits, heart rate etc.
    has todo_list: list = []; # List of things to do by the user.
    has session_assitant_type: string = '';

    can send_query_to_router with query entry;
    can 'You a smart assitant role picker, using the user query you have to decide what sort of an assitant the user requires to get help.'
    pick_assitant_type(query: 'The question the user has.': str) -> 'response': str by llm(
        temperature=1,
        max_tokens=1024,
        incl_info=(role_examples)
    );
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
    router_with_llm(query: 'Query from the user to be routed.': str, todo_list: 'The tasks to be done by the user in the future.': list, user_data: 'data about the health status of the user.': dict) -> task_type by llm(
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
    can 'You are an personal assistant.Answer in friendly detailed manner only answer only questions that are in your domain if you dont know the answer then say that you dont know in a polite manner'
    chat_llm(user_data: 'data about the user': list, query: 'Question from the user to be answered.': str, chat_history: 'Previous Conversation with the user': list) -> 'response': str by llm(temperature=0.7);
    can 'You run in a loop of Thought, Action, PAUSE, Observation.\nAt the end of the loop you output an Answer\nUse Thought to describe your thoughts about the question you have been asked.\nUse Action to run one of the actions available to you - then return PAUSE.\nObservation will be the result of running those actions.\n\nYour available actions are:\n\ngetUserData:\ne.g. getUserData:\nProvides the data about the user in json format\n\ngetUserTasks:\ne.g. getUserTasks:\nProvides the users task list in json format\n\ngetCurrentDateTime:\ne.g. getCurrentDateTime:\nProvides the current data and time\nExample session:\n\nQuestion: Whats my name?\nThought: I need to find the users name\nAction: getUserData:\nPAUSE \n\nYou will be called again with this:\n\nObservation: { "name":"vinura",\n"age": 20,\n"Pressure": (120, 80),\n"Married": False\n}\n\nIf you have the answer, output it as the Answer.\n\nAnswer:Your name is Vinura.'
    agent_llm(query: 'The question the user has.': str) -> 'response': str by llm(temperature=0.7, max_tokens=1024);
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
