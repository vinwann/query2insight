
- [Query2Insight](#Query2Insight)
  - [Introduction](#introduction)
  - [Features](#Features)
  - [Dependencies](#dependencies)
  - [Launching](#Launching)
  - [Technologies](#Technologies)
  - [Data spatial architecture](#Data-spatial-architecture)
  - [LLM-calls](#LLM-calls)

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
    <li>JacLang (Graph-Based Language)</li>
    <li>Groq (llama3.1-70b)</li>
    <li>MTLLM API library</li>
    <li>Streamlit (GUI)</li>
    <li>TinyDB (Database Management for metadata)</li>
    <li>Ollama (Generate embeddings)</li>
    <li>ChromaDB (Vector database)</li>
    <li>RAG Engine (Retrieval-Augmented Generation)</li>
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

  <p>The Query walker is responsible for carrying the user input to the respective nodes getting the LLM response and returning the LLM response to the session node to be saved. For each user input a query walker is created</p>
  #### Lifecycle of a Query-walker
  <ol>
    <li>Spawning in the session node</li>
    <li>Visiting the router node and getting directed to "RAG", "QA" or "DATA" (end nodes)nodes</li>
    <li>Visiting the end nodes and collecting the LLM response</li>
    <li>Returning to the session node through the router node</li>
    <li>Saving the LLM response</li>
    <li>Death</li>
</ol>
  
## LLM-calls

![llm calls](https://github.com/user-attachments/assets/7deb4eb5-39b4-49cf-8ca6-590d2bb320ea)
 

