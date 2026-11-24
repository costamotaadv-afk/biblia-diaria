"""Testes puros da busca na Bíblia (porte de ``lib/busca_biblia.dart``)."""

from core.busca_biblia import buscar_na_biblia, normalizar_para_busca


def test_normalizar_remove_acentos_e_caixa():
    assert normalizar_para_busca('São João') == 'sao joao'
    assert normalizar_para_busca('  CÉU  ') == 'ceu'


def test_busca_vazia_retorna_lista_vazia():
    assert buscar_na_biblia([], '   ') == []


def test_busca_encontra_versiculo_sem_acento():
    livros = [
        {
            'nome': 'Gênesis',
            'capitulos': [
                {
                    'numero': 1,
                    'versiculos': [
                        {'numero': 1, 'texto': 'No princípio, criou Deus o céu e a terra.'},
                        {'numero': 2, 'texto': 'E a terra era sem forma.'},
                    ],
                }
            ],
        }
    ]
    resultados = buscar_na_biblia(livros, 'ceu')
    assert len(resultados) == 1
    assert resultados[0].referencia == 'Gênesis 1:1'


def test_busca_limita_resultados():
    livros = [
        {
            'nome': 'L',
            'capitulos': [
                {
                    'numero': 1,
                    'versiculos': [
                        {'numero': i, 'texto': 'palavra alvo aqui'} for i in range(1, 6)
                    ],
                }
            ],
        }
    ]
    resultados = buscar_na_biblia(livros, 'alvo', limite=3)
    assert len(resultados) == 3
