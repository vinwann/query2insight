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

glob user_data_dic:obj;

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
    api_key: obj = chat_meta_db.get_api_key();
    print("api_key ",api_key);
    if api_key == None {
        api_key = "";
    }
    new_api_key: str = st.sidebar.text_input("Groq API key", value=api_key, type='password');
    print("new_api_key ",new_api_key);
    if new_api_key != api_key {
        if verify_groq_api_key(new_api_key) {
            chat_meta_db.update_api_key(new_api_key);
            os.environ["GROQ_API_KEY"] = new_api_key;
        } else {
            st.warning("Please set a vaild Groq api key");
        }
    }
    if (page == "Chat") {
        if ready_to_chat == False {
            st.warning(
                "Please set your Groq API key."
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
    :g: user_data_dic;
    st.markdown("""
    <style>
        .card {
            border-radius: 5px;
            padding: 5px;
            margin: 10px 0px;
            background-color: #f0f2f6;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .metric-card {
            border-radius: 5px;
            padding: 15px;
            margin: 5px 0px;
            background-color: #ffffff;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        .metric-label {
            font-size: 0.8rem;
            font-weight: bold;
            color: #555;
        }
        .metric-value {
            font-size: 1.2rem;
            font-weight: bold;
            color: #0f52ba;
        }
        .gauge {
            width: 100%;
            height: 5px;
            background-color: #e0e0e0;
            border-radius: 10px;
            overflow: hidden;
        }
        .gauge-fill {
            height: 100%;
            background-color: #4CAF50;
            transition: width 0.5s ease-out;
        }
    </style>
    """, unsafe_allow_html=True);
    user_data_dic = chat_meta_db.get_user_data();
    st.title("Health Dashboard");
    # Personal Information
    #st.markdown("<div class='card'>", unsafe_allow_html=True);

    st.subheader(" \U0001F4CB Personal Information");
    [col1, col2, col3] = st.columns(3);
    col1.markdown(create_metric_card("Name", user_data_dic["name"]), unsafe_allow_html=True);
    col2.markdown(create_metric_card("Age", f"{user_data_dic['age_years']} years"), unsafe_allow_html=True);
    col3.markdown(create_metric_card("Marital Status", "Married" if user_data_dic["Married"] else "Single"), unsafe_allow_html=True);
    st.markdown("</div>", unsafe_allow_html=True);

    # Physical Measurements
    #st.markdown("<div class='card'>", unsafe_allow_html=True);
    st.divider();
    st.subheader(" \U0001F4CF Physical Measurements");
    [col1, col2, col3] = st.columns(3);
    col1.markdown(create_metric_card("Height", f"{user_data_dic['Height_cm']} cm"), unsafe_allow_html=True);
    col2.markdown(create_metric_card("Weight", f"{user_data_dic['Weight_kg']} kg"), unsafe_allow_html=True);
    if (user_data_dic['Height_cm'] == 0)
    {
        bmi = 0;
    }
    else{
        bmi = user_data_dic['Weight_kg'] / ((user_data_dic['Height_cm'] / 100) ** 2);
    }
    col3.markdown(create_gauge(bmi, 18.5, 30, "BMI", "kg/m²"), unsafe_allow_html=True);
    st.markdown("</div>", unsafe_allow_html=True);

    # Vital Signs
    #st.markdown("<div class='card'>", unsafe_allow_html=True);
    st.divider();
    st.subheader(" \U00002764\U0000FE0F Vital Signs");
    [col1, col2] = st.columns(2);
    if (len(user_data_dic["Blood_Pressure_mmHg"]) >0){
        [systolic, diastolic] = user_data_dic["Blood_Pressure_mmHg"];
    }
    else{
        [systolic, diastolic] = [0,0];
    }
    col1.markdown(create_gauge(systolic, 90, 180, "Systolic Blood Pressure", "mmHg"), unsafe_allow_html=True);
    col2.markdown(create_gauge(diastolic, 60, 120, "Diastolic Blood Pressure", "mmHg"), unsafe_allow_html=True);
    st.markdown("</div>", unsafe_allow_html=True);

    # Lifestyle
    #st.markdown("<div class='card'>", unsafe_allow_html=True);
    st.divider();
    st.subheader(" \U0001F3C3 Lifestyle");
    [col1, col2] = st.columns(2);
    col1.markdown(create_metric_card("Alcohol Intake", user_data_dic["Alcohol_Intake"]), unsafe_allow_html=True);
    col2.markdown(create_metric_card("Physical Activity", user_data_dic["Physical_Activity_Level"]), unsafe_allow_html=True);
    st.markdown("</div>", unsafe_allow_html=True);

    # Blood Tests
    #st.markdown("<div class='card'>", unsafe_allow_html=True);
    st.divider();
    st.subheader(" \U0001FA78 Blood Tests");
    [col1, col2, col3] = st.columns(3);
    col1.markdown(create_gauge(user_data_dic['Cholesterol_Level_mg_dL'], 150, 300, "Total Cholesterol", "mg/dL"), unsafe_allow_html=True);
    col2.markdown(create_gauge(user_data_dic['HDL_mg_dL'], 40, 80, "HDL", "mg/dL"), unsafe_allow_html=True);
    col3.markdown(create_gauge(user_data_dic['LDL_mg_dL'], 70, 160, "LDL", "mg/dL"), unsafe_allow_html=True);
    [col1, col2, col3] = st.columns(3);
    col1.markdown(create_gauge(user_data_dic['Triglycerides_mg_dL'], 50, 200, "Triglycerides", "mg/dL"), unsafe_allow_html=True);
    col2.markdown(create_gauge(user_data_dic['Blood_Glucose_mg_dL'], 70, 140, "Blood Glucose", "mg/dL"), unsafe_allow_html=True);
    col3.markdown(create_gauge(user_data_dic['HbA1c_percent'], 4, 8, "HbA1c", "%"), unsafe_allow_html=True);
    st.markdown("</div>", unsafe_allow_html=True);
}

can create_metric_card(label:str, value:str){
    unit = "";
    output = f"<div class='metric-card'> <div class='metric-label'>{label}</div> <div class='metric-value'>{value} {unit}</div></div>";
    return output;
}
can create_gauge(value:int, min_val:int, max_val:int, label:str, unit:str = "") {
    percentage = (value - min_val) / (max_val - min_val) * 100;
    output = "<div class='metric-card'><div class='metric-label'>" + label + 
             "</div><div class='metric-value'>" + str(value) + " " + unit + 
             "</div><div class='gauge'><div class='gauge-fill' style='width: " + str(percentage) + 
             "%;'></div></div></div>";
    return output;
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
