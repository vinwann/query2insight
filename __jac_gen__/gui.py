from __future__ import annotations
from jaclang.plugin.feature import JacFeature as _Jac
from jaclang.plugin.builtin import *
from jaclang import jac_import as __jac_import__
__jac_import__(target='streamlit', base_path=__file__, mod_bundle=__name__, lng='py', absorb=False, mdl_alias='st', items={})
import streamlit as st
__jac_import__(target='PIL', base_path=__file__, mod_bundle=__name__, lng='py', absorb=False, mdl_alias=None, items={'Image': False})
from PIL import Image

def start() -> None:
    st.markdown("<h1 style='text-align: center;'>Query2Insight</h1>", unsafe_allow_html=True)
    st.markdown('\n    <style>\n    .full-width-button {\n        display: flex;\n        justify-content: center;\n    }\n    .stButton button {\n        width: 100%;\n    }\n    </style>\n    ', unsafe_allow_html=True)
    if st.sidebar.button('start new chat'):
        return True
    return False

def chat_interface(query_walker: walker, session: node) -> None:
    for message in session.chat_history:
        with st.chat_message(message['role']):
            st.markdown(message['content'])
    if (input := st.chat_input('How can I help you?')):
        query_walker.inquiry_by_user = input
        with st.chat_message('user'):
            st.markdown(query_walker.inquiry_by_user)

def display_response(response: str) -> None:
    with st.chat_message('assistant'):
        stream = st.write(response)