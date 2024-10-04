import:py streamlit as st;
import:py from PIL, Image;
import:py from db_service, TinyDBService;
import:py pathlib;
import:py os;
import:py requests;
import:py json;

glob chat_meta_db = TinyDBService('meta');

glob page = "chat";

glob ready_to_chat = False;

can start(backend_state: bool) {
    :g: page ;
    
    :g: chat_meta_db ;
    
    :g: ready_to_chat ;
    
    ready_to_chat = backend_state;
    st.set_page_config(
        page_title="q2i",
        page_icon="🤖",
        layout="wide"
    );
    st.markdown(
        "<h1 style='text-align: center;'>Query2Insight</h1>",
        unsafe_allow_html=True
    );
    st.markdown(
        """\n"""
            """    <style>\n"""
            """    .full-width-button {\n"""
            """        display: flex;\n"""
            """        justify-content: center;\n"""
            """    }\n"""
            """    .stButton button {\n"""
            """        width: 100%;\n"""
            """    }\n"""
            """    </style>\n"""
            """    """,
        unsafe_allow_html=True
    );
    start_new_chat = False;
    if ready_to_chat {
        page = st.sidebar.selectbox("Go to", ["Chat", "Details"]);
    } else {
        page = st.sidebar.selectbox("Go to", ["Details", "Chat"]);
    }
    if (page == "Chat") {
        if ready_to_chat == False {
            st.warning(
                "Please set your Groq API key in the User Details page."
            );
        }
        if st.sidebar.button('Start new chat') {
            start_new_chat = True;
        }
        uploaded_file = st.sidebar.file_uploader("Choose a file");
        if (uploaded_file != None) {
            save_path = "uploaded_files";
            if (os.path.exists(save_path) != True) {
                os.mkdir(save_path);
            }
            file_path = save_path + "/" + uploaded_file.name;
            
            try  {
                with open(file_path, "wb") as f {
                    f.write(uploaded_file.getbuffer());
                }
                ;    st.sidebar.write(
                    f"File saved successfully at: {file_path}"
                );
                start_new_chat = "new upload";
            } except Exception as e {
                st.sidebar.write(f"Error: {e}");
            }
        }
        st.sidebar.subheader("Previous Chats");
        for chat_id in reversed(chat_meta_db.return_all_chats()) {
            if (st.sidebar.button(
                f"{chat_id['name']}",
                key=f"btn_{chat_id['id']}"
            )) {
                start_new_chat = chat_id['id'];
            }
        }
        return start_new_chat;
    } else {
        user_data();
        return "user details";
    }
}

can user_data() {
    :g: chat_meta_db ;
    
    st.subheader("User Details");
    api_key: obj = chat_meta_db.get_api_key();
    if api_key == None {
        api_key = "";
    }
    new_api_key: str = st.text_input("Groq API Key", api_key);
    if new_api_key != api_key {
        if verify_groq_api_key(new_api_key) {
            chat_meta_db.update_api_key(new_api_key);
            os.environ["GROQ_API_KEY"] = new_api_key;
        } else {
            st.warning("Please set a vaild Groq api key");
        }
    }
}

can chat_interface(query_walker: walker, session: node) {
    if (page == "Chat" and ready_to_chat) {
        for message in session.chat_history {
            with st.chat_message(message["role"]) {
                st.markdown(message["content"]);
            }
        }
        if input := st.chat_input("How can I help you?") {
            query_walker.inquiry_by_user = input;
            
            #query_walker.user_query.append({  "role": "user", "content": query_walker.query});
            with st.chat_message("user") {
                st.markdown(query_walker.inquiry_by_user);
            }
        }
    }
}

can display_response(response: str) {
    if (page == "Chat" and ready_to_chat) {
        with st.chat_message("assistant") {
            stream = st.write(response);
        }
    }
}

can verify_groq_api_key(api_key: str) {
    url = "https://api.groq.com/openai/v1/chat/completions";
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    };
    payload = {
        "model": "mixtral-8x7b-32768",
        "messages": [{"role": "user", "content": "Hello"}],
        "max_tokens": 1
    };
    try  {
        response = requests.post(
            url,
            headers=headers, data=json.dumps(payload)
        );
        if response.status_code == 200 {
            print("valid api key");
            return True;
        } else {
            print("Invalid api key");
            return False;
        }
    } except Exception as e {
        print("Invalid api key");
        return False;
    }
}
