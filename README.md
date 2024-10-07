
- [Query2Insight](#Query2Insight)
  - [Introduction](#introduction)
    - [Chat Interface](#Chat-Interface)
    - [User Data Information Dashboard](#User-Data-Information-Dashboard)
  - [Features](#Features)
  - [Dependencies](#dependencies)
  - [Launching](#Launching)
  - [Technologies](#Technologies)
  - [Data spatial architecture](#Data-spatial-architecture)
    - [Nodes](#Nodes)
    - [Walkers](#Walkers)
      - [Chat-walker](#Chat-walker)
      - [Query-walker](#Query-walker)
  - [LLM-calls](#LLM-calls)
    - [Picking Assistant Type](#Picking-Assistant-Type)
    - [Suggest Chat Name](#Suggest-Chat-Name)
    - [Picking End Node](#Picking-End-Node)
    - [Answering Using RAG](#Answering-Using-RAG)
    - [Provided User Data Identification](#Provided-User-Data-Identification)
    - [Asking Questions From User](#Asking-Questions-From-User)
    - [QnA with User](#QnA-with-User)

# Query2Insight

## Introduction
  <p>Query2Insight is a fully open-source LLM-powered chatbot designed to provide users with tailored insights and assistance across various domains. The app integrates several cutting-edge technologies to enhance its functionality and user experience. It utilizes the power of Groq for efficient model execution and leverages Streamlit for an interactive user interface. The backend is supported by TinyDBService, which manages the chatbot's metadata and session information. The RAG engine plays a crucial role in retrieving context-specific information to ensure accurate responses. The chatbot is capable of handling different types of queries, including those related to programming, health, and general assistance.</p>

### Chat Interface

![ui](https://github.com/user-attachments/assets/cadeb92d-7fd6-4358-8069-f30f321a7683)

### User Data Information Dashboard

![User data](https://github.com/user-attachments/assets/bec542ae-66a8-4a74-8e85-c72d49a8520b)

## Features

<ul>
  <li>Upload your own documents and ask questions from them.</li>
  <li>Ask questions about yourself.</li>
  <li>Tell the LLM about yourself and it will save your information.</li>
  
</ul>

### Chatting with LLM

https://github.com/user-attachments/assets/65eceefa-0af3-421b-843c-b249107f7061

### User data updating through chat

https://github.com/user-attachments/assets/6be69801-2e86-40c9-9462-55d960e0b3cf

## Dependencies

Install the necessary dependencies by running. Ensure that you have Python 3.12

```shell
python3 -m pip install -r requirements.txt
```

## Launching 

After installing all dependencies, you can run the app with the following command.

```shell
streamlit run app.py
```
Make sure to delete the Jac cache before each run.

```shell
jac clean
```

## Technologies
  <div align="left">
  <ul>
    <li>Python (3.12)</li>
    <li>Jac-Lang </li>
    <li>Groq (llama3.1-70b)</li>
    <li>MTLLM API library</li>
    <li>Streamlit (GUI)</li>
    <li>TinyDB (Database Management for metadata, user data, and API keys)</li>
    <li>Ollama (Generate embeddings)</li>
    <li>ChromaDB (Vector database)</li>
    <li>RAG Engine </li>
  </ul>
</div>

## Data-spatial-architecture

![Data spactial structure](https://github.com/user-attachments/assets/9b3f0fcb-2778-4306-a153-ec16df701b36)

### Nodes 

<ul>
    <li>Root : Starting node</li>
    <li>User: Node to store user data</li>
    <li>Session: Node which manages chat sessions. For each chat, there exists a session node that is unique for each chat. Each session node will have its own child nodes</li>
    <li>Router: Node that is responsible for directing the Query walker to "RAG", "DATA" or "QA" according to the user's input</li>
    <li>RAG: If the query walker enters the user input is given into the RAG engine and answered accordingly</li>
    <li>DATA: If the user has provided information about themselves, update the database accordingly, and ask further questions if needed to gather more details about the user</li>
    <li>QA: Answer questions asked by the user using their personal data in the database</li>
</ul>

### Walkers 

#### Chat-walker

  <p>The Chat walker is responsible for creating new chat sessions and switching between chats when the user commands it</p>
  
#### Query-walker

  <p>The Query walker is responsible for carrying the user input to the respective nodes getting the LLM response and returning the LLM response to the session node to be saved. For each user input, a query walker is created</p>
  
  ####  Lifecycle of a Query-walker
  
  <ol>
    <li>Spawning in the session node</li>
    <li>Visiting the router node and getting directed to "RAG", "QA" or "DATA" (end nodes)nodes</li>
    <li>Visiting the end nodes and collecting the LLM response</li>
    <li>Returning to the session node through the router node</li>
    <li>Saving the LLM response</li>
    <li>Death</li>
</ol>
  
## LLM-calls

![llm calls](https://github.com/user-attachments/assets/89fa8ae5-0537-40d7-ba98-9d912b7b269c)

### Picking Assistant Type

<p>To aid LLM calls done with the user input at the end nodes an assistant type is generated using the user's input </p>

```shell
glob role_examples: 'Examples for picking assitant role. You are not limited to these examples. if you are uncertain of the role pick personal assistant': dict[str, str] = {
'Can you help me with programming?': 'Programming assistant',
'Hi help me with this python ?': 'Programming assistant',
'What are the symptoms of low blood pressure?': 'Health assistant',
'Hi?': 'personal assistant',
'Hi who am i?': 'personal assistant'
};


can 'You a smart assitant role picker, using the user query you have to decide what sort of an assistant the user requires to get help.'
    pick_assitant_type(query: 'The question the user has.': str) -> 'response': str by llm(
        temperature=1,
        max_tokens=1024,
        incl_info=(role_examples)
    );
```
### Suggest Chat Name

<p>Considering the chat history and the previous name suggested by the LLM a chat name is generated. This will be updated with every interaction in the chat to reflect the overall picture of the chat</p>

```shell
can 'You a smart assitant that has to pick a name for a chat an user has had. Looking at the chat history suggest a name for the chat and the previous name recommned by you. The name has to be short not more than 5 words and capture the entire conversation'
    chat_name_suggestion(chat_history: 'The chat history': list, chat_name: 'The previous chat name suggested': str) -> 'response': str by llm(temperature=1);
```
### Picking End Node

<p>According to the user's input the end node is determined. The LLM is made to reason with only three options given. Examples are given to help the LLM decide the type</p>

```shell
enum task_type {
    RAG_TYPE: 'Need to use Retrivable information in specific topic' = "RAG",
    QA_TYPE: 'Need to use given user information about themselves or questions asked about themselves' = "user_qa",
    DATA_TYPE: 'Need to use when the user is giving an answer to a question asked by the assistant to update user data' = 'DATA'
}

glob router_examples: 'Examples of routing of a query.if you are uncerteain of the routing method pick task_type.QA_TYPE. Do not pick anything outside of these three options': dict[str, task_type] = {
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

router_with_llm(query: 'Query from the user to be routed.': str, user_data: 'data about the health status of the user.': dict, chat_history: 'Previous Conversation with the user': list) -> task_type by llm(
        method="Reason",
        temperature=0.0,
        incl_info=(router_examples)
    );
```
### Answering Using RAG

<p>The LLM uses the retrieved context about the user input via the vector database and answers the user</p>

```shell
can 'You an Assistant.The type of assistant you are is given in assistant_type use it to give detailed answers. Give a response based on the retrived_context in a detailed manner'
    chat_llm(query: 'Question from the user to be answered.': str, assistant_type: 'The type of assistant you are use this when answering ': str, retrived_context: 'Retrived information from expert articles': list, chat_history: 'Previous Conversation with the user': list) -> 'response': str by llm(temperature=1);
```

### Provided User Data Identification

<p>The application has to collect data about the user through conversation. When the user has provided such information it has to be converted the field that should be updated and the data. The LLM is tasked with identifying the fields in the user data table and matching the data given by the user to or creating a new field and matching the data to that field. The LLM is given examples and is supposed to reason and output a list of data fields and the corresponding data </p>

```shell

glob data_examples: 'Examples of the data given by the user and field that you should reply as and the data to be inputted in that field': dict[str, task_type] = {
'My name is john?': ["name:John"],
'John': ["name:John"],
'Im 25 years old': ["age_years:25"],
'My blood pressure is 145 90': ["Blood_Pressure_mmHg:145 90"],
'John white': ["name:john white"],
'male': ["Gender:male"],
'Yes Im married': ["Married:True"],
'the world is round': "None",
'I cant tell you my weight':"None",
'My name is  John and im 25 years old': ["name:John","age_years:25"]
};

can 'Using answer given by the user output the field that should be updated in user_data.if you are uncertain of a field , the user refuses to answer or the answer doesnt make sense return None. If the suitable field is not in user data create one. Use the exmples given and only reply in that formate. Do not ask questions'
    data_entry(user_data: 'data about the user': list, answer: 'Data given by the user to be answered.': str, chat_history: 'Previous Conversation with the user': list) -> 'response': list by llm(
        method="Reason",
        temperature=0,
        incl_info=(data_examples)
    );
```

### Asking Questions From User

<p>This LLM call will ask further questions from the user if there are more data it needs to find out</p>

```shell
can 'You are an personal assistant that asks questions from a user.The user has answered a question to fill up the user data regarding the user you have to thank the user for answering.The field the answered data belongs to has been determind and given in the field variable. IF the user data is empty ask only one question from the user for an empty field in the user data to get information about the user.'
    chat_llm(user_data: 'data about the user': list, query: 'Answer from the user to be answered.': str,field:'Assied data field for the users answer ':str, chat_history: 'Previous Conversation with the user': list) -> 'response': str by llm(temperature=0.7);
```

### QnA with User

<p>This LLM call will answer the user using the user data in the database</p>

```shell
can 'You are an personal assistant.Answer in friendly detailed manner only answer only questions that are in your domain if you dont know the answer then say that you dont know in a polite manner. IF the user data is empty ask questions about the fields in the user data to get information about the user'
    chat_llm(user_data: 'data about the user': list, query: 'Question from the user to be answered.': str, chat_history: 'Previous Conversation with the user': list) -> 'response': str by llm(temperature=0.7);
```
