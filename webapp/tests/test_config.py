"""Caso B3 — validação da chave Pix (porte de test/config_negocio_test.dart)."""

from core.config import CHAVE_PIX, chave_pix_valida


def test_chave_configurada_e_email_valido():
    assert chave_pix_valida(CHAVE_PIX), (
        'A chave Pix do app não pode ser inválida em produção.'
    )


def test_rejeita_formatos_invalidos():
    assert chave_pix_valida('sem-arroba') is False
    assert chave_pix_valida('123') is False
    assert chave_pix_valida('a@b') is False  # sem domínio com ponto
    assert chave_pix_valida('') is False
    assert chave_pix_valida('nome@dominio sem ponto') is False
