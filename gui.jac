import:py streamlit as st;
import:py from PIL, Image;
import:py from dbService, TinyDBService;
import:py pathlib;
import:py os;
import:py requests;
import:py json;

glob chat_meta_db = TinyDBService('meta');

glob page = "chat";

glob ready_to_chat = False;

glob user_data_dic: obj;

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
    start_new_chat = False;# Initialize the flag for starting a new chat
    
    # Sidebar selection to navigate between "Chat" and "Details" pages
    if ready_to_chat {
        page = st.sidebar.selectbox("Go to", ["Chat", "Details"]);
    } else {
        page = st.sidebar.selectbox("Go to", ["Details", "Chat"]);
    }
    # Get the current API key from the database
    api_key: obj = chat_meta_db.get_api_key();
    if api_key == None {
        api_key = "";
    }
    # Input for Groq API key in the sidebar
    new_api_key: str = st.sidebar.text_input(
        "Groq API key",
        value=api_key, type='password'
    );
    
    # If a new API key is provided, verify it and update the database
    if new_api_key != api_key {
        if verify_groq_api_key(new_api_key) {
            chat_meta_db.update_api_key(new_api_key); # Update the API key in the database
            os.environ["GROQ_API_KEY"] = new_api_key;# Set the API key as an environment variable
        } else {
            st.warning("Please set a valid Groq API key");
            new_api_key = api_key;# Revert to the old API key if invalid
        }
    } else {
        new_api_key = api_key;# No change to API key
    }
    # If the page is "Chat"
    if (page == "Chat") {
        if ready_to_chat == False {
            st.warning("Please set your Groq API key."); # Show a warning if the API key isn't set
        }
        # Button to start a new chat
        if st.sidebar.button('Start new chat') {
            start_new_chat = True;
        }
        # File uploader for users to upload files
        uploaded_file = st.sidebar.file_uploader("Choose a file");
        if (uploaded_file != None) {
            save_path = "uploaded_files";# Directory to save uploaded files
            if (os.path.exists(save_path) != True) {
                os.mkdir(save_path); # Create directory if it doesn't exist
            }
            file_path = save_path + "/" + uploaded_file.name;
            
            try  {
                # Save the uploaded file
                with open(file_path, "wb") as f {
                    f.write(uploaded_file.getbuffer());
                }
                st.sidebar.write(
                    f"File saved successfully at: {file_path}"
                );
                start_new_chat = "new upload";# Set the chat status to "new upload"
            } except Exception as e {
                st.sidebar.write(f"Error: {e}");
            }
        }
        # List of previous chats to select from
        st.sidebar.subheader("Previous Chats");
        for chat_id in reversed(chat_meta_db.return_all_chats()) {
            if (st.sidebar.button(
                f"{chat_id['name']}",
                key=f"btn_{chat_id['id']}"
            )) {
                start_new_chat = chat_id['id'];# Load an existing chat session
            }
        }
        return start_new_chat; # Return the status for starting a new chat
    }
    # If the page is "Details"
     else {
        user_data(); # Call the user data function to display user details
        return "user details"; # Return the details page status
    }
}

can user_data() {
    :g: chat_meta_db ;
    
    :g: user_data_dic ;
    
    st.markdown(
        """\n"""
        """    <style>\n"""
        """        .card {\n"""
        """            border-radius: 5px;\n"""
        """            padding: 5px;\n"""
        """            margin: 10px 0px;\n"""
        """            background-color: #f0f2f6;\n"""
        """            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);\n"""
        """        }\n"""
        """        .metric-card {\n"""
        """            border-radius: 5px;\n"""
        """            padding: 15px;\n"""
        """            margin: 5px 0px;\n"""
        """            background-color: #ffffff;\n"""
        """            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);\n"""
        """        }\n"""
        """        .metric-label {\n"""
        """            font-size: 0.8rem;\n"""
        """            font-weight: bold;\n"""
        """            color: #555;\n"""
        """        }\n"""
        """        .metric-value {\n"""
        """            font-size: 1.2rem;\n"""
        """            font-weight: bold;\n"""
        """            color: #0f52ba;\n"""
        """        }\n"""
        """        .gauge {\n"""
        """            width: 100%;\n"""
        """            height: 5px;\n"""
        """            background-color: #e0e0e0;\n"""
        """            border-radius: 10px;\n"""
        """            overflow: hidden;\n"""
        """        }\n"""
        """        .gauge-fill {\n"""
        """            height: 100%;\n"""
        """            background-color: #4CAF50;\n"""
        """            transition: width 0.5s ease-out;\n"""
        """        }\n"""
        """    </style>\n"""
        """    """,
        unsafe_allow_html=True
    );
    user_data_dic = chat_meta_db.get_user_data();
    st.title("Health Dashboard");
    
    # Personal Information
    
    #st.markdown("<div class='card'>", unsafe_allow_html=True);
    st.subheader(" \U0001F4CB Personal Information");
    [col1, col2, col3] = st.columns(3);
    col1.markdown(
        create_metric_card("Name", user_data_dic["name"]),
        unsafe_allow_html=True
    );
    col2.markdown(
        create_metric_card(
            "Age",
            f"{user_data_dic['age_years']} years"
        ),
        unsafe_allow_html=True
    );
    col3.markdown(
        create_metric_card(
            "Occupation",
            f"{user_data_dic['Occupation']}"
        ),
        unsafe_allow_html=True
    );
    st.markdown("</div>", unsafe_allow_html=True);
    
    # Physical Measurements
    
    #st.markdown("<div class='card'>", unsafe_allow_html=True);
    st.divider();
    st.subheader(" \U0001F4CF Physical Measurements");
    [col1, col2, col3] = st.columns(3);
    col1.markdown(
        create_metric_card(
            "Height",
            f"{user_data_dic['Height_cm']} cm"
        ),
        unsafe_allow_html=True
    );
    col2.markdown(
        create_metric_card(
            "Weight",
            f"{user_data_dic['Weight_kg']} kg"
        ),
        unsafe_allow_html=True
    );
    if (user_data_dic['Height_cm'] == 0) {
        bmi = 0;
    } else {
        bmi = user_data_dic['Weight_kg'] / ((user_data_dic['Height_cm'] / 100) ** 2);
    }
    col3.markdown(
        create_gauge(bmi, 18.5, 30, "BMI", "kg/m²"),
        unsafe_allow_html=True
    );
    st.markdown("</div>", unsafe_allow_html=True);
    
    # Vital Signs
    
    #st.markdown("<div class='card'>", unsafe_allow_html=True);
    st.divider();
    st.subheader(" \U00002764\U0000FE0F Vital Signs");
    [col1, col2] = st.columns(2);
    if (len(user_data_dic["Blood_Pressure_mmHg"]) > 0) {
        [systolic, diastolic] = user_data_dic["Blood_Pressure_mmHg"];
    } else {
        [systolic, diastolic] = [0, 0];
    }
    col1.markdown(
        create_gauge(
            systolic,
            90,
            180,
            "Systolic Blood Pressure",
            "mmHg"
        ),
        unsafe_allow_html=True
    );
    col2.markdown(
        create_gauge(
            diastolic,
            60,
            120,
            "Diastolic Blood Pressure",
            "mmHg"
        ),
        unsafe_allow_html=True
    );
    st.markdown("</div>", unsafe_allow_html=True);
    
    # Lifestyle
    
    #st.markdown("<div class='card'>", unsafe_allow_html=True);
    st.divider();
    st.subheader(" \U0001F3C3 Lifestyle");
    [col1, col2] = st.columns(2);
    col1.markdown(
        create_metric_card(
            "Alcohol Intake",
            user_data_dic["Alcohol_Intake"]
        ),
        unsafe_allow_html=True
    );
    col2.markdown(
        create_metric_card(
            "Physical Activity",
            user_data_dic["Physical_Activity_Level"]
        ),
        unsafe_allow_html=True
    );
    st.markdown("</div>", unsafe_allow_html=True);
    
    # Blood Tests
    
    #st.markdown("<div class='card'>", unsafe_allow_html=True);
    st.divider();
    st.subheader(" \U0001FA78 Blood Tests");
    [col1, col2, col3] = st.columns(3);
    col1.markdown(
        create_gauge(
            user_data_dic['Cholesterol_Level_mg_dL'],
            150,
            300,
            "Total Cholesterol",
            "mg/dL"
        ),
        unsafe_allow_html=True
    );
    col2.markdown(
        create_gauge(
            user_data_dic['HDL_mg_dL'],
            40,
            80,
            "HDL",
            "mg/dL"
        ),
        unsafe_allow_html=True
    );
    col3.markdown(
        create_gauge(
            user_data_dic['LDL_mg_dL'],
            70,
            160,
            "LDL",
            "mg/dL"
        ),
        unsafe_allow_html=True
    );
    [col1, col2, col3] = st.columns(3);
    col1.markdown(
        create_gauge(
            user_data_dic['Triglycerides_mg_dL'],
            50,
            200,
            "Triglycerides",
            "mg/dL"
        ),
        unsafe_allow_html=True
    );
    col2.markdown(
        create_gauge(
            user_data_dic['Blood_Glucose_mg_dL'],
            70,
            140,
            "Blood Glucose",
            "mg/dL"
        ),
        unsafe_allow_html=True
    );
    col3.markdown(
        create_gauge(
            user_data_dic['HbA1c_percent'],
            4,
            8,
            "HbA1c",
            "%"
        ),
        unsafe_allow_html=True
    );
    st.markdown("</div>", unsafe_allow_html=True);
}

can create_metric_card(label: str, value: str) {
    unit = "";
    output = f"<div class='metric-card'> <div class='metric-label'>{label}</div> <div class='metric-value'>{value} {unit}</div></div>";
    return output;
}

can create_gauge(value: int, min_val: int, max_val: int, label: str, unit: str="") {
    percentage = (value - min_val) / (max_val - min_val) * 100;
    output = "<div class='metric-card'><div class='metric-label'>" + label + "</div><div class='metric-value'>" + str(value) + " " + unit + "</div><div class='gauge'><div class='gauge-fill' style='width: " + str(percentage) + "%;'></div></div></div>";
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
