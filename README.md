
- [Query2Insight](#Query2Insight)
  - [Introduction](#introduction)
  - [Dependencies](#dependencies)
  - [Technologies](#Technologies)
  - [Data spatial architecture](#Data-spatial-architecture)
  - [LLM-calls](#LLM-calls)

# Query2Insight

## Introduction
  <p>Query2Insight is a fully open-source LLM-powered chatbot designed to provide users with tailored insights and assistance across various domains. The app integrates several cutting-edge technologies to enhance its functionality and user experience. It utilizes the power of Groq for efficient model execution and leverages Streamlit for an interactive user interface. The backend is supported by TinyDBService, which manages the chatbot's metadata and session information. The RAG engine plays a crucial role in retrieving context-specific information to ensure accurate responses. The chatbot is capable of handling different types of queries, including those related to programming, health, and general assistance.</p>

![ui](https://github.com/user-attachments/assets/cadeb92d-7fd6-4358-8069-f30f321a7683)

https://github.com/user-attachments/assets/65eceefa-0af3-421b-843c-b249107f7061

## Dependencies

Install the necessary dependencies by running. Ensure that you have Python 3.12

```shell
python3 -m pip install -r requirements.txt
```
## Technologies
  <div align="left">
  <ul>
    <li>Python</li>
    <li>JacLang (Graph-Based Language)</li>
    <li>Groq (llama3-70b)</li>
    <li>MTLLM API library</li>
    <li>Streamlit (GUI)</li>
    <li>TinyDB (Database Management for metadata)</li>
    <li>Ollama (Generate embeddings)</li>
    <li>ChromaDB (Vector database)</li>
    <li>RAG Engine (Retrieval-Augmented Generation)</li>
  </ul>
</div>



![User data](https://github.com/user-attachments/assets/bec542ae-66a8-4a74-8e85-c72d49a8520b)


https://github.com/user-attachments/assets/6be69801-2e86-40c9-9462-55d960e0b3cf

## Data-spatial-architecture

![Data spactial structure](https://github.com/user-attachments/assets/9b3f0fcb-2778-4306-a153-ec16df701b36)

## LLM-calls

![llm calls](https://github.com/user-attachments/assets/7deb4eb5-39b4-49cf-8ca6-590d2bb320ea)
 

