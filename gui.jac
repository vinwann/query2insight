import:py streamlit as st;
import:py from PIL, Image;

can start() {
    
    st.markdown("<h1 style='text-align: center;'>Query2Insight</h1>", unsafe_allow_html=True);
    st.markdown(
    """
    <style>
    .full-width-button {
        display: flex;
        justify-content: center;
    }
    .stButton button {
        width: 100%;
    }
    </style>
    """,
    unsafe_allow_html=True);
    if st.sidebar.button('start new chat'){
        return True;
    }
    return False;
}

can chat_interface(query_walker:walker,session:node){
    for message in session.chat_history{
        with st.chat_message(message["role"]) {
            st.markdown(message["content"]);
        }
    }
    if input := st.chat_input("How can I help you?") {
        query_walker.inquiry_by_user = input;
        #query_walker.user_query.append({  "role": "user", "content": query_walker.query});
        with st.chat_message("user"){
            st.markdown(query_walker.inquiry_by_user);
        }
    }
}

can display_response(response:str){
    with st.chat_message("assistant"){
        stream = st.write(response);
    }
}