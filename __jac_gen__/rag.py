from __future__ import annotations
from jaclang.plugin.feature import JacFeature as _Jac
from jaclang.plugin.builtin import *
from jaclang import jac_import as __jac_import__
from dataclasses import dataclass as __jac_dataclass__
__jac_import__(target='langchain_community.document_loaders', base_path=__file__, mod_bundle=__name__, lng='py', absorb=False, mdl_alias=None, items={'PyPDFDirectoryLoader': False})
from langchain_community.document_loaders import PyPDFDirectoryLoader
__jac_import__(target='langchain_text_splitters', base_path=__file__, mod_bundle=__name__, lng='py', absorb=False, mdl_alias=None, items={'RecursiveCharacterTextSplitter': False})
from langchain_text_splitters import RecursiveCharacterTextSplitter
__jac_import__(target='langchain.schema.document', base_path=__file__, mod_bundle=__name__, lng='py', absorb=False, mdl_alias=None, items={'Document': False})
from langchain.schema.document import Document
__jac_import__(target='langchain_community.embeddings.ollama', base_path=__file__, mod_bundle=__name__, lng='py', absorb=False, mdl_alias=None, items={'OllamaEmbeddings': False})
from langchain_community.embeddings.ollama import OllamaEmbeddings
__jac_import__(target='langchain_community.vectorstores.chroma', base_path=__file__, mod_bundle=__name__, lng='py', absorb=False, mdl_alias=None, items={'Chroma': False})
from langchain_community.vectorstores.chroma import Chroma
__jac_import__(target='os', base_path=__file__, mod_bundle=__name__, lng='py', absorb=False, mdl_alias=None, items={})
import os

@_Jac.make_obj(on_entry=[], on_exit=[])
@__jac_dataclass__(eq=False)
class rag_engine(_Jac.Obj):
    file_path: str = _Jac.has_instance_default(gen_func=lambda: 'books')
    chroma_path: str = _Jac.has_instance_default(gen_func=lambda: 'chroma')

    def __post_init__(self) -> None:
        documents: list = self.load_documents()
        chunks: list = self.split_documents(documents)
        self.add_to_chroma(chunks)

    def load_documents(self) -> None:
        document_loader = PyPDFDirectoryLoader(self.file_path)
        return document_loader.load()

    def split_documents(self, documents: list[Document]) -> None:
        text_splitter = RecursiveCharacterTextSplitter(chunk_size=800, chunk_overlap=80, length_function=len, is_separator_regex=False)
        return text_splitter.split_documents(documents)

    def get_embedding_function(self) -> None:
        embeddings = OllamaEmbeddings(model='nomic-embed-text')
        return embeddings

    def add_chunk_id(self, chunks: str) -> None:
        """
    This ability will create unique IDs for chunks. 
    Example: "books/Oxford Handbook.pdf:100:2:
    Template: "Page Source:Page Number:Chunk Index"
    """
        last_page_id = None
        current_chunk_index = 0
        for chunk in chunks:
            source = chunk.metadata.get('source')
            page = chunk.metadata.get('page')
            current_page_id = f'{source}:{page}'
            if current_page_id == last_page_id:
                current_chunk_index += 1
            else:
                current_chunk_index = 0
            chunk_id = f'{current_page_id}:{current_chunk_index}'
            last_page_id = current_page_id
            chunk.metadata['id'] = chunk_id
        return chunks

    def add_to_chroma(self, chunks: list[Document]) -> None:
        """
    Creating/ Updating the Vector Database
    """
        db = Chroma(persist_directory=self.chroma_path, embedding_function=self.get_embedding_function())
        chunks_with_ids = self.add_chunk_id(chunks)
        existing_items = db.get(include=[])
        existing_ids = set(existing_items['ids'])
        new_chunks = []
        for chunk in chunks_with_ids:
            if chunk.metadata['id'] not in existing_ids:
                new_chunks.append(chunk)
        if len(new_chunks):
            print('adding new documents')
            new_chunk_ids = [chunk.metadata['id'] for chunk in new_chunks]
            db.add_documents(new_chunks, ids=new_chunk_ids)
        else:
            print('no new documents to add')

    def get_from_chroma(self, query: str) -> None:
        """
    Retreive the relevent chunks upon a query.
    """
        db = Chroma(persist_directory=self.chroma_path, embedding_function=self.get_embedding_function())
        results = db.similarity_search_with_score(query, k=5)
        print(type(results))
        return results