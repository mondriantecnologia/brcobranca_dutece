# encoding: utf-8

module Brcobranca
  module Remessa
    class Base # Classe base para retornos bancários
      attr_accessor :nome_arquivo
      attr_accessor :caminho_arquivo
      attr_accessor :objeto
      attr_accessor :boletos
      attr_accessor :codigo_cliente
      attr_accessor :baixa_manual
    end
  end
end
