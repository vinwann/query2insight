import:py random;
import:py uuid;
import:py re;
import:py json;
import:py from mtllm.llms, Groq;  # Importing necessary modules including Groq (used for LLM calls)
import:jac gui;
import:py streamlit as st;  # Streamlit for GUI handling
import:py from db_service, TinyDBService;  # Database service to manage metadata and user data
include:jac rag;  # Including the retrieval-augmented generation (RAG) engine

# Connecting the database that stores metadata and user data
glob chat_meta_db = TinyDBService('meta');  

glob api_key = None;  # API key placeholder

glob llm = None;  # Placeholder for LLM object

# Initialize RAG engine
glob RagEngine: rag_engine = rag_engine();

# Default assistant type is set to 'programming assistant'
glob assitant_type: string = "programming assiatant";

glob current_session_id:str = "";  # Placeholder for the current session ID

glob ready_to_chat = False;  # Flag to indicate if the app is ready for chat

'''
App states: defines different states of the app's lifecycle.
'''
enum app_states {
    BOOT_UP = "boot up",  # Initial state of the app
    RUNNING = "running",  # Normal chatting state
    NEW = "new chat"  # State when creating a new chat
}

glob app_state = app_states.BOOT_UP;  # Default state is boot-up

'''
Task types for routing user inputs to the correct end node based on their query
'''
enum task_type {
    RAG_TYPE: 'Need to use Retrievable information in a specific topic' = "RAG",
    QA_TYPE: 'Need to use provided user information' = "user_qa",
    DATA_TYPE: 'Used when updating user data' = 'DATA'
}

'''
Examples for routing queries based on task type
'''
glob router_examples: 'Examples of routing of a query. If uncertain, pick QA_TYPE' = {
    'whats my name?': task_type.QA_TYPE,
    'How to reduce cholestrole': task_type.RAG_TYPE,
    'whats are my tasks for today?': task_type.QA_TYPE,
    'Do you think im healthy?': task_type.QA_TYPE,
    'What are the symptoms of low blood pressure?': task_type.RAG_TYPE,
    'What is a variable in python?': task_type.RAG_TYPE,
    'What is programming?': task_type.RAG_TYPE,
    'Can you tell me the definition of high blood pressure?': task_type.RAG_TYPE,
    'Im John': task_type.DATA_TYPE,
    '25 years old': task_type.DATA_TYPE
};

'''
Examples for reasoning user data and corresponding fields
'''
glob data_examples: 'Examples of user data and respective fields' = {
    'My name is john?': ["name:John"],
    'John': ["name:John"],
    'Im 25 years old': ["age_years:25"],
    'My blood pressure is 145 90': ["Blood_Pressure_mmHg:145 90"],
    'John white': ["name:john white"],
    'male': ["Gender:male"],
    'Yes Im married': ["Married:True"],
    'the world is round': "None",
    'I cant tell you my weight': "None",
    'My name is John and im 25 years old': ["name:John", "age_years:25"]
};

'''
Examples for determining the assistant's role based on user queries
'''
glob role_examples: 'Examples for picking assistant role' = {
    'Can you help me with programming?': 'Programming assistant',
    'Hi help me with this python?': 'Programming assistant',
    'What are the symptoms of low blood pressure?': 'Health assistant',
    'Hi?': 'personal assistant',
    'Hi who am I?': 'personal assistant'
};

# User node containing user-specific data
node user {
    has user_name: string = "user";
}

'''
Query walker carries user input to LLM calls and returns responses
'''
walker query {
    has session_id: string = '';
    has just_init: bool = True;
    has inquiry_by_user: string = '';
    has user_query: dict = {"role": '', "content": ''};
    has query_state: int = 0;
    has user_data: 'data about the user’s health status' = {};
    has session_assitant_type: string = '';
}

'''
Session node contains session-specific data like chat history and user data
'''
node session {
    has session_id: string = '';
    has chat_history: list = [];
    has chat_file_name: string = 'chat';
    has tinydb_service: obj = '';
    has user_data: dict = {};
    has chat_name: string = "";
    has session_assitant_type: string = '';

    can send_query_to_router with query entry;
    can pick_assitant_type(query: 'The question the user has.': str) -> 'response': str by llm(
        temperature=1, max_tokens=1024, incl_info=(role_examples)
    );
    can chat_name_suggestion(chat_history: 'The chat history': list, chat_name: 'Previous chat name': str) -> 'response': str by llm(temperature=1);
}

'''
Chat walker handles creating new chat sessions and switching between them
'''
walker chat {
    has new_chat: bool = True;
    can create_session with user entry;
    can chat_session with session entry;
}

'''
Create the graph structure for chat sessions
'''
walker create_graph {
    has user_data: dict = {};
    can generate_graph with `root entry;
}

'''
Router node directs queries to the appropriate end node (RAG, QA, or DATA)
'''
node router {
    can direct with query entry;
    can router_with_llm(query: 'User query', user_data: 'User health data', chat_history: list) -> task_type by llm(
        method="Reason", temperature=0.0, incl_info=(router_examples)
    );
}

# RAG node for answering questions using retrieved context
node RAG {
    has answer: string = '';
    can print_output with query entry;
    can chat_llm(query: 'User query', assistant_type: str, retrived_context: list, chat_history: list) -> 'response': str by llm(temperature=1);
}

# QA node for answering user queries based on personal data
node user_QA {
    has answer: string = '';
    can print_output with query entry;
    can chat_llm(user_data: list, query: str, chat_history: list) -> 'response': str by llm(temperature=0.7);
}

# DATA node for updating user data and asking follow-up questions
node user_DATA {
    has answer: string = '';
    has data_entry_answer: string= '';
    can print_output with query entry;
    can data_entry(user_data: list, answer: str, chat_history: list) -> 'response': list by llm(
        method="Reason", temperature=0, incl_info=(data_examples)
    );
    can chat_llm(user_data: list, query: str, field: str, chat_history: list) -> 'response': str by llm(temperature=0.7);
}

# Main function handles the app's lifecycle and user interactions
can main() {
    :g: chat_meta_db ;
    :g: app_state ;
    :g: current_session_id ;
    :g: api_key ;
    :g: ready_to_chat ;
    :g: llm ;
    try {
        feedback_from_gui = gui.start(ready_to_chat);  # Getting feedback from the GUI
        
        if (api_key and feedback_from_gui != "user details") {
            # Handling different feedback and states (new chat, document upload, switching sessions)
            if (type(feedback_from_gui) == bool and feedback_from_gui == True) {
                app_state = app_states.NEW;
            } elif (type(feedback_from_gui) == str) {
                if (feedback_from_gui == "new upload") {
                    # Loading and processing documents for the RAG engine
                    documents: list = RagEngine.load_documents();
                    chunks: list = RagEngine.split_documents(documents);
                    RagEngine.add_to_chroma(chunks);
                } else {
                    # Switching to an existing chat session
                    current_session_id = feedback_from_gui;
                }
            }
            # Boot-up state: Initialize the system and create a chat graph
            if (app_state == app_states.BOOT_UP) {
                os.environ["GROQ_API_KEY"] = api_key;
                llm = Groq(model_name="llama-3.1-70b-versatile");
                create_graph() spawn root;
                chat() spawn [root-->](`?user)[0];
            } elif (app_state == app_states.NEW) {
                chat() spawn [root-->](`?user)[0];
            } else {
                # Switching between sessions and spawning query walkers
                count: int = 0;
                for i in [[root-->](`?user)[0]-->](`?session) {
                    if i.session_id == current_session_id {
                        break;
                    }
                    count += 1;
                }
                query() spawn [[root-->](`?user)[0]-->](`?session)[count];
            }
        } else {
            # If no API key, try to fetch it from the database
            api_key = chat_meta_db.get_api_key();
            if api_key {
                ready_to_chat = True;
            } else {
                ready_to_chat = False;
            }
        }
    } except Exception as e {
        print(f"Error: {e}");  
    }
}
