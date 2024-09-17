from __future__ import annotations
from jaclang.plugin.feature import JacFeature as _Jac
from jaclang.plugin.builtin import *
from jaclang import jac_import as __jac_import__
from dataclasses import dataclass as __jac_dataclass__
from enum import Enum as __jac_Enum__, auto as __jac_auto__
__jac_import__(target='random', base_path=__file__, mod_bundle=__name__, lng='py', absorb=False, mdl_alias=None, items={})
import random
__jac_import__(target='uuid', base_path=__file__, mod_bundle=__name__, lng='py', absorb=False, mdl_alias=None, items={})
import uuid
__jac_import__(target='re', base_path=__file__, mod_bundle=__name__, lng='py', absorb=False, mdl_alias=None, items={})
import re
__jac_import__(target='json', base_path=__file__, mod_bundle=__name__, lng='py', absorb=False, mdl_alias=None, items={})
import json
__jac_import__(target='mtllm.llms', base_path=__file__, mod_bundle=__name__, lng='py', absorb=False, mdl_alias=None, items={'Groq': False})
from mtllm.llms import Groq
__jac_import__(target='gui', base_path=__file__, mod_bundle=__name__, lng='jac', absorb=False, mdl_alias=None, items={})
import gui
__jac_import__(target='streamlit', base_path=__file__, mod_bundle=__name__, lng='py', absorb=False, mdl_alias='st', items={})
import streamlit as st
__jac_import__(target='db_service', base_path=__file__, mod_bundle=__name__, lng='py', absorb=False, mdl_alias=None, items={'TinyDBService': False})
from db_service import TinyDBService
__jac_import__(target='rag', base_path=__file__, mod_bundle=__name__, lng='jac', absorb=True, mdl_alias=None, items={})
from rag import *
import rag
chat_meta_db = TinyDBService('meta')
llm = Groq(model_name='llama-3.1-70b-versatile')
state = 0
RagEngine: rag_engine = rag_engine()
assitant_type: string = 'programming assiatant'

def main() -> None:
    global state
    if gui.start():
        state = 1
    if state == 0:
        with open('user_info.json', 'r') as f:
            imported_data = json.load(f)
        _Jac.spawn_call(create_graph(user_data=imported_data['user_data'], todo_list=imported_data['todo_list']), _Jac.get_root())
        state = 2
        _Jac.spawn_call(chat(), (lambda x: [i for i in x if isinstance(i, user)])(_Jac.edge_ref(_Jac.get_root(), target_obj=None, dir=_Jac.EdgeDir.OUT, filter_func=None, edges_only=False))[0])
    elif state == 1:
        _Jac.spawn_call(chat(), (lambda x: [i for i in x if isinstance(i, user)])(_Jac.edge_ref(_Jac.get_root(), target_obj=None, dir=_Jac.EdgeDir.OUT, filter_func=None, edges_only=False))[0])
        state = 2
    else:
        _Jac.spawn_call(query(), (lambda x: [i for i in x if isinstance(i, session)])(_Jac.edge_ref((lambda x: [i for i in x if isinstance(i, user)])(_Jac.edge_ref(_Jac.get_root(), target_obj=None, dir=_Jac.EdgeDir.OUT, filter_func=None, edges_only=False))[0], target_obj=None, dir=_Jac.EdgeDir.OUT, filter_func=None, edges_only=False))[-1])

class task_type(__jac_Enum__):
    RAG_TYPE = 'RAG'
    QA_TYPE = 'user_qa'
router_examples: dict[str, task_type] = {'whats my name?': task_type.QA_TYPE, 'How to reduce cholrestrole': task_type.RAG_TYPE, 'whats are my tasks for today?': task_type.QA_TYPE, 'Do you think im healthy?': task_type.QA_TYPE, 'What are the symptoms of low blood pressure?': task_type.RAG_TYPE, 'What is a varible in python?': task_type.RAG_TYPE, 'What is programming?': task_type.RAG_TYPE, 'Can you tell me the definition of high blood presure': task_type.RAG_TYPE}
role_examples: dict[str, str] = {'Can you help me with programming?': 'Programming assistant', 'Hi help me with this pyhton ?': 'Programming assistant', 'What are the symptoms of low blood pressure?': 'Health assistant', 'Hi?': 'personal assistant', 'Hi who am i?': 'personal assistant'}

@_Jac.make_node(on_entry=[], on_exit=[])
@__jac_dataclass__(eq=False)
class user(_Jac.Node):
    user_name: string = _Jac.has_instance_default(gen_func=lambda: 'user')

@_Jac.make_walker(on_entry=[], on_exit=[])
@__jac_dataclass__(eq=False)
class query(_Jac.Walker):
    session_id: string = _Jac.has_instance_default(gen_func=lambda: '')
    just_init: bool = _Jac.has_instance_default(gen_func=lambda: True)
    inquiry_by_user: string = _Jac.has_instance_default(gen_func=lambda: '')
    user_query: dict = _Jac.has_instance_default(gen_func=lambda: {'role': '', 'content': ''})
    query_state: int = _Jac.has_instance_default(gen_func=lambda: 0)
    user_data: dict = _Jac.has_instance_default(gen_func=lambda: {})
    todo_list: list = _Jac.has_instance_default(gen_func=lambda: [])
    session_assitant_type: string = _Jac.has_instance_default(gen_func=lambda: '')

@_Jac.make_node(on_entry=[_Jac.DSFunc('send_query_to_router', query)], on_exit=[])
@__jac_dataclass__(eq=False)
class session(_Jac.Node):
    """
Chat session of a user. This node contains the session_id, user_data and todo_list.
This should also include the chat history. Can have multiple chat sessions.
"""
    session_id: string = _Jac.has_instance_default(gen_func=lambda: '')
    chat_history: list = _Jac.has_instance_default(gen_func=lambda: [])
    chat_file_name: string = _Jac.has_instance_default(gen_func=lambda: 'chat')
    tinydb_service: obj = _Jac.has_instance_default(gen_func=lambda: '')
    user_data: dict = _Jac.has_instance_default(gen_func=lambda: {})
    todo_list: list = _Jac.has_instance_default(gen_func=lambda: [])
    session_assitant_type: string = _Jac.has_instance_default(gen_func=lambda: '')

    def send_query_to_router(self, _jac_here_: query) -> None:
        if _jac_here_.just_init:
            _jac_here_.just_init = False
            gui.chat_interface(_jac_here_, self)
            _jac_here_.session_id = self.session_id
            _jac_here_.user_data = self.user_data
            _jac_here_.todo_list = self.todo_list
            _jac_here_.chat_history = []
            if len(_jac_here_.inquiry_by_user) > 0:
                self.session_assitant_type = self.pick_assitant_type(_jac_here_.inquiry_by_user)
                print(self.session_assitant_type)
                _jac_here_.session_assitant_type = self.session_assitant_type
        if _jac_here_.query_state == 0:
            if len(_jac_here_.inquiry_by_user) > 0:
                self.chat_history.append({'role': 'user', 'content': _jac_here_.inquiry_by_user})
                self.tinydb_service.insert_data({'role': 'user', 'content': _jac_here_.inquiry_by_user})
                if _Jac.visit_node(_jac_here_, _Jac.edge_ref(self, target_obj=None, dir=_Jac.EdgeDir.OUT, filter_func=None, edges_only=False)):
                    pass
            _jac_here_.query_state = 1
        elif _jac_here_.query_state == 1:
            self.chat_history.append(_jac_here_.user_query)
            self.tinydb_service.insert_data(_jac_here_.user_query)
            _jac_here_.query_state = 2

    def pick_assitant_type(self, query: str) -> str:
        output = _Jac.with_llm(file_loc=__file__, model=llm, model_params={'temperature': 1, 'max_tokens': 1024}, scope='streamlit_fronend(Module).session(node)', incl_info=[('role_examples', role_examples)], excl_info=[], inputs=[('The question the user has.', str, 'query', query)], outputs=('response', 'str'), action='You a smart assitant role picker, using the user query you have to decide what sort of an assitant the user requires to get help.')
        try:
            return eval(output)
        except:
            return output

@_Jac.make_node(on_entry=[], on_exit=[])
@__jac_dataclass__(eq=False)
class data(_Jac.Node):
    """
Consists of user data such as age, pressure, married status.
"""
    user_data: dict = _Jac.has_instance_default(gen_func=lambda: {'age': 0, 'Pressure': (0, 0), 'Married': False})

@_Jac.make_node(on_entry=[], on_exit=[])
@__jac_dataclass__(eq=False)
class todo(_Jac.Node):
    """
List of things to do by the user.
"""
    todo_list: list = _Jac.has_instance_default(gen_func=lambda: [])

@_Jac.make_walker(on_entry=[_Jac.DSFunc('create_session', user), _Jac.DSFunc('chat_session', session)], on_exit=[])
@__jac_dataclass__(eq=False)
class chat(_Jac.Walker):
    """
This is the chat walker which will be used to chat with the user.
The create_session ability:
- gather the user data and todo list from connected nodes using filters.
- Creates a new session with the user data and todo list.
- Spawns the chat session with the session id.
"""
    new_chat: bool = _Jac.has_instance_default(gen_func=lambda: True)

    def create_session(self, _jac_here_: user) -> None:
        global chat_meta_db
        if self.new_chat:
            data_node = (lambda x: [i for i in x if isinstance(i, data)])(_Jac.edge_ref(_jac_here_, target_obj=None, dir=_Jac.EdgeDir.OUT, filter_func=None, edges_only=False))[0]
            todo_node = (lambda x: [i for i in x if isinstance(i, todo)])(_Jac.edge_ref(_jac_here_, target_obj=None, dir=_Jac.EdgeDir.OUT, filter_func=None, edges_only=False))[0]
            new_session_id = str(uuid.uuid4())
            n = _Jac.connect(left=_jac_here_, right=session(session_id=new_session_id, user_data=data_node.user_data, todo_list=todo_node.todo_list, tinydb_service=TinyDBService('chat' + new_session_id)), edge_spec=_Jac.build_edge(is_undirected=False, conn_type=None, conn_assign=None))
            chat_meta_db.insert_data({'id': 'chat' + new_session_id})
            if _Jac.visit_node(self, n):
                pass

    def chat_session(self, _jac_here_: session) -> None:
        _Jac.spawn_call(query(), _jac_here_)
        self.new_chat = False
        end = _jac_here_
        _Jac.connect(left=end, right=(end := router()), edge_spec=_Jac.build_edge(is_undirected=False, conn_type=None, conn_assign=None))
        _Jac.connect(left=end, right=RAG(), edge_spec=_Jac.build_edge(is_undirected=False, conn_type=None, conn_assign=None))
        _Jac.connect(left=end, right=user_QA(), edge_spec=_Jac.build_edge(is_undirected=False, conn_type=None, conn_assign=None))
        _Jac.connect(left=end, right=user_TODO(), edge_spec=_Jac.build_edge(is_undirected=False, conn_type=None, conn_assign=None))
        if _Jac.visit_node(self, _Jac.edge_ref(_jac_here_, target_obj=None, dir=_Jac.EdgeDir.IN, filter_func=None, edges_only=False)):
            pass

@_Jac.make_walker(on_entry=[_Jac.DSFunc('generate_graph', _Jac.RootType)], on_exit=[])
@__jac_dataclass__(eq=False)
class create_graph(_Jac.Walker):
    """
This is where we create the graph.
"""
    user_data: dict = _Jac.has_instance_default(gen_func=lambda: {})
    todo_list: list = _Jac.has_instance_default(gen_func=lambda: [])

    def generate_graph(self, _jac_here_: _Jac.RootType) -> None:
        end = _jac_here_
        _Jac.connect(left=end, right=(end := user()), edge_spec=_Jac.build_edge(is_undirected=False, conn_type=None, conn_assign=None))
        _Jac.connect(left=end, right=data(user_data=self.user_data), edge_spec=_Jac.build_edge(is_undirected=False, conn_type=None, conn_assign=None))
        _Jac.connect(left=end, right=todo(todo_list=self.todo_list), edge_spec=_Jac.build_edge(is_undirected=False, conn_type=None, conn_assign=None))

@_Jac.make_node(on_entry=[_Jac.DSFunc('direct', query)], on_exit=[])
@__jac_dataclass__(eq=False)
class router(_Jac.Node):

    def direct(self, _jac_here_: query) -> None:
        if len(_jac_here_.inquiry_by_user) > 0:
            task: task_type = self.router_with_llm(query=_jac_here_.inquiry_by_user, todo_list=_jac_here_.todo_list, user_data=_jac_here_.user_data)
            print(task)
            if task == task_type.RAG_TYPE:
                if _Jac.visit_node(_jac_here_, (lambda x: [i for i in x if isinstance(i, RAG)])(_Jac.edge_ref(self, target_obj=None, dir=_Jac.EdgeDir.OUT, filter_func=None, edges_only=False))):
                    pass
            elif (task == task_type.QA_TYPE) | (task != None):
                if _Jac.visit_node(_jac_here_, (lambda x: [i for i in x if isinstance(i, user_QA)])(_Jac.edge_ref(self, target_obj=None, dir=_Jac.EdgeDir.OUT, filter_func=None, edges_only=False))):
                    pass
            else:
                gui.display_response('Kindly add a routing method by using @ in the start of your question\nTo visit TODO : @TODO\nTo visit RAG : @RAG\nTo visit QA : @QA')
                _jac_here_.user_query['role'] = 'assistant'
                _jac_here_.user_query['content'] = 'Kindly add a routing method by using @ in the start of your question\nTo visit TODO : @TODO\nTo visit RAG : @RAG\nTo visit QA : @QA'
                _jac_here_.inquiry_by_user = ''
                _jac_here_.query_state = True
                if _Jac.visit_node(_jac_here_, _Jac.edge_ref(self, target_obj=None, dir=_Jac.EdgeDir.IN, filter_func=None, edges_only=False)):
                    pass
        elif _Jac.visit_node(_jac_here_, _Jac.edge_ref(self, target_obj=None, dir=_Jac.EdgeDir.IN, filter_func=None, edges_only=False)):
            pass

    def router_with_llm(self, query: str, todo_list: list, user_data: dict) -> task_type:
        output = _Jac.with_llm(file_loc=__file__, model=llm, model_params={'method': 'Reason', 'temperature': 0.0}, scope='streamlit_fronend(Module).router(node)', incl_info=[('router_examples', router_examples)], excl_info=[], inputs=[('Query from the user to be routed.', str, 'query', query), ('The tasks to be done by the user in the future.', list, 'todo_list', todo_list), ('data about the health status of the user.', dict, 'user_data', user_data)], outputs=('', 'task_type'), action='route the query to the appropriate task type')
        try:
            return eval(output)
        except:
            return output

@_Jac.make_node(on_entry=[_Jac.DSFunc('print_output', query)], on_exit=[])
@__jac_dataclass__(eq=False)
class RAG(_Jac.Node):
    answer: string = _Jac.has_instance_default(gen_func=lambda: '')

    def print_output(self, _jac_here_: query) -> None:
        tinydb_service = TinyDBService('chat' + _jac_here_.session_id)
        self.answer = self.chat_llm(assistant_type=_jac_here_.session_assitant_type, query=_jac_here_.inquiry_by_user, retrived_context=RagEngine.get_from_chroma(query=_jac_here_.inquiry_by_user), chat_history=tinydb_service.return_chat_history())
        gui.display_response(self.answer)
        _jac_here_.user_query['role'] = 'assistant'
        _jac_here_.user_query['content'] = self.answer
        _jac_here_.inquiry_by_user = ''
        if _Jac.visit_node(_jac_here_, _Jac.edge_ref(self, target_obj=None, dir=_Jac.EdgeDir.IN, filter_func=None, edges_only=False)):
            pass

    def chat_llm(self, query: str, assistant_type: str, retrived_context: list, chat_history: list) -> str:
        output = _Jac.with_llm(file_loc=__file__, model=llm, model_params={'temperature': 1}, scope='streamlit_fronend(Module).RAG(node)', incl_info=[], excl_info=[], inputs=[('Question from the user to be answered.', str, 'query', query), ('The type of assistant you are use this when answering ', str, 'assistant_type', assistant_type), ('Retrived information from expert articles', list, 'retrived_context', retrived_context), ('Previous Conversation with the user', list, 'chat_history', chat_history)], outputs=('response', 'str'), action='You an Assistant.The type of assistant you are is given in assistant_type use it to give detailed answers. Give a response based on the retrived_context in a detailed manner')
        try:
            return eval(output)
        except:
            return output

@_Jac.make_node(on_entry=[_Jac.DSFunc('print_output', query)], on_exit=[])
@__jac_dataclass__(eq=False)
class user_QA(_Jac.Node):
    answer: string = _Jac.has_instance_default(gen_func=lambda: '')

    def print_output(self, _jac_here_: query) -> None:
        tinydb_service = TinyDBService('chat' + _jac_here_.session_id)
        self.answer = self.chat_llm(user_data=_jac_here_.user_data, query=_jac_here_.inquiry_by_user, chat_history=tinydb_service.return_chat_history())
        gui.display_response(self.answer)
        _jac_here_.user_query['role'] = 'assistant'
        _jac_here_.user_query['content'] = self.answer
        _jac_here_.inquiry_by_user = ''
        if _Jac.visit_node(_jac_here_, _Jac.edge_ref(self, target_obj=None, dir=_Jac.EdgeDir.IN, filter_func=None, edges_only=False)):
            pass

    def chat_llm(self, user_data: list, query: str, chat_history: list) -> str:
        output = _Jac.with_llm(file_loc=__file__, model=llm, model_params={'temperature': 0.7}, scope='streamlit_fronend(Module).user_QA(node)', incl_info=[], excl_info=[], inputs=[('data about the user', list, 'user_data', user_data), ('Question from the user to be answered.', str, 'query', query), ('Previous Conversation with the user', list, 'chat_history', chat_history)], outputs=('response', 'str'), action='You are an personal assistant.Answer in friendly detailed manner only answer only questions that are in your domain if you dont know the answer then say that you dont know in a polite manner')
        try:
            return eval(output)
        except:
            return output

    def agent_llm(self, query: str) -> str:
        output = _Jac.with_llm(file_loc=__file__, model=llm, model_params={'temperature': 0.7, 'max_tokens': 1024}, scope='streamlit_fronend(Module).user_QA(node)', incl_info=[], excl_info=[], inputs=[('The question the user has.', str, 'query', query)], outputs=('response', 'str'), action='You run in a loop of Thought, Action, PAUSE, Observation.\nAt the end of the loop you output an Answer\nUse Thought to describe your thoughts about the question you have been asked.\nUse Action to run one of the actions available to you - then return PAUSE.\nObservation will be the result of running those actions.\n\nYour available actions are:\n\ngetUserData:\ne.g. getUserData:\nProvides the data about the user in json format\n\ngetUserTasks:\ne.g. getUserTasks:\nProvides the users task list in json format\n\ngetCurrentDateTime:\ne.g. getCurrentDateTime:\nProvides the current data and time\nExample session:\n\nQuestion: Whats my name?\nThought: I need to find the users name\nAction: getUserData:\nPAUSE \n\nYou will be called again with this:\n\nObservation: { "name":"vinura",\n"age": 20,\n"Pressure": (120, 80),\n"Married": False\n}\n\nIf you have the answer, output it as the Answer.\n\nAnswer:Your name is Vinura.')
        try:
            return eval(output)
        except:
            return output

@_Jac.make_node(on_entry=[_Jac.DSFunc('print_output', query)], on_exit=[])
@__jac_dataclass__(eq=False)
class user_TODO(_Jac.Node):
    answer: string = _Jac.has_instance_default(gen_func=lambda: '')
    name: str = _Jac.has_instance_default(gen_func=lambda: 'Every reply should be i dont know, thats the only response you can give')

    def print_output(self, _jac_here_: query) -> None:
        tinydb_service = TinyDBService('chat' + _jac_here_.session_id)
        self.answer = self.chat_llm(todo_list=_jac_here_.todo_list, query=_jac_here_.inquiry_by_user, chat_history=tinydb_service.return_chat_history())
        gui.display_response(self.answer)
        _jac_here_.user_query['role'] = 'assistant'
        _jac_here_.user_query['content'] = self.answer
        _jac_here_.inquiry_by_user = ''
        if _Jac.visit_node(_jac_here_, _Jac.edge_ref(self, target_obj=None, dir=_Jac.EdgeDir.IN, filter_func=None, edges_only=False)):
            pass

    def chat_llm(self, todo_list: list, query: str, chat_history: list) -> str:
        output = _Jac.with_llm(file_loc=__file__, model=llm, model_params={'temperature': 0.7, 'max_tokens': 1024}, scope='streamlit_fronend(Module).user_TODO(node)', incl_info=[], excl_info=[], inputs=[('data about the health status of the user', list, 'todo_list', todo_list), ('The tasks to be done by the user in the future.', str, 'query', query), ('Previous Conversation with the user', list, 'chat_history', chat_history)], outputs=('response', 'str'), action='Every reply should be i dont know, thats the only response you can give')
        try:
            return eval(output)
        except:
            return output