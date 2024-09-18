import:py streamlit as st;
import:py from PIL, Image;
import:py from db_service, TinyDBService;

glob chat_meta_db = TinyDBService('meta');

can start() {
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
    if st.sidebar.button('start new chat') {
        return True;
    }
    st.sidebar.subheader("Previous Chats");
    print(chat_meta_db.return_all_chats());
    
    for chat_id in chat_meta_db.return_all_chats()
    {
        if (st.sidebar.button(f"Chat {chat_id['id']}", key=f"btn_{chat_id['id']}"))
        {
            return True;
        }
    }
    return False;
}

can chat_interface(query_walker: walker, session: node) {
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

can display_response(response: str) {
    with st.chat_message("assistant") {
        stream = st.write(response);
    }
}
