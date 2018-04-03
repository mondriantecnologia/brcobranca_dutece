module Brcobranca
  module Remessa
    class Bradesco < Base
      
      def parametros
        Parametro.find 1
      end

      def num_sequencia
        1
      end

      def gerar_arquivo
        @arquivo = File.open(self.caminho_arquivo, "w")
        
        if self.objeto.class == ArquivoRemessa
          primeira_linha = self.cabecalho_arquivo_remessa(self.objeto.tipo)
          @arquivo.write(primeira_linha)
          if self.objeto.tipo == "Boleto"
            numero_de_registros = self.corpo_arquivo_remessa_boleto(self.baixa_manual)
          else
            numero_de_registros = self.corpo_arquivo_remessa_fatura
          end
          rodape = self.rodape_arquivo_remessa(numero_de_registros)
          @arquivo.write(rodape)
        elsif self.objeto.class == PagamentoEstorno
          primeira_linha = self.cabecalho_pagamento_estorno
          @arquivo.write(primeira_linha)
          numero_de_registros = self.corpo_pagamento_estorno
          rodape = self.rodape_pagamento_estorno(numero_de_registros)
          @arquivo.write(rodape)
        elsif self.objeto.class == Repasse
          primeira_linha = self.cabecalho_arquivo_repasse
          @arquivo.write(primeira_linha)
          numero_de_registros = self.corpo_arquivo_repasse
          rodape = self.rodape_arquivo_repasse(numero_de_registros)
          @arquivo.write(rodape)
        elsif self.objeto.class == ArquivoFornecedor
          primeira_linha = self.cabecalho_arquivo_repasse
          @arquivo.write(primeira_linha)
          numero_de_registros = self.corpo_arquivo_fornecedor
          rodape = self.rodape_arquivo_repasse(numero_de_registros)
          @arquivo.write(rodape)          
        end
        
        @arquivo.close

        comando = "sed -i 's/$/\\r/' #{self.caminho_arquivo}"    
        system(comando)
      end
      
      def cabecalho_arquivo_remessa(tipo = "Fatura")
        primeira_linha = "01" # 1 a 2 identificaçao do registro e identificaçao do arquivo remessa
        primeira_linha << "REMESSA" # 3 a 9 literal
        primeira_linha << "01" # 10 a 11 Código de Serviço
        primeira_linha << "COBRANCA".ljust(15," ") # 12 a 26 
        if tipo == "Boleto"
          primeira_linha << self.parametros.cod_cliente_boleto.rjust(20,"0") # 27 a 43 codigo da empresa
        else
          primeira_linha << self.parametros.cod_cliente.rjust(20,"0") # 27 a 43 codigo da empresa
        end
        primeira_linha << I18n.transliterate(self.parametros.cedente)[0,30].ljust(30," ").upcase # 44 a 76 nome da empresa
        primeira_linha << "237".ljust(3," ")  # 77 a 79 numero do bradesco
        primeira_linha << "BRADESCO".ljust(15," ") # 80 a 94 bradesco
        primeira_linha << Time.now.strftime('%d%m%y').to_s.rjust(6,"0") # 95 a 100 data de gravaçao do arquivo
        primeira_linha << "".ljust(8," ") # 101 a 108 branco
        primeira_linha << "MX".ljust(2," ") # 109 a 110 identificação do sistema 
        primeira_linha << self.parametros.sequencial_arquivo_remessa.to_s.rjust(7,"0")   # 111 a 117 numero sequencial de remessa 
        primeira_linha << "".ljust(277," ") # 118 a 394 branco
        primeira_linha << num_sequencia.to_s.rjust(6,"0") # 395 a 400 numero sequencial do registro de um em um 
        primeira_linha << "\n"
        p = self.parametros
        p.sequencial_arquivo_remessa += 1
        p.save 
        return primeira_linha
      end

      def cabecalho_pagamento_estorno
        primeira_linha =  "0" #001 A 001 - Identificação do Registro - 001 -Obrigatório – fixo “zero”(0)
        primeira_linha << self.parametros.codigo_de_comunicacao.to_s.rjust(8,'0') # 002 A 009 - Código de Comunicação - 008 
        primeira_linha << '2' #010 A 010 -  Tipo de Inscrição da Empresa Pagadora - 1 = CPF / 2 = CNPJ / 3= OUTROS
        primeira_linha << self.parametros.cnpj_cedente.rjust(15,'0') #011 A 025 - CNPJ/CPF Base da Empresa Pagadora
        primeira_linha << I18n.transliterate(self.parametros.cedente)[0,40].ljust(40," ").upcase # 26 a 65 nome da empresa      
        primeira_linha << '20' #066 A 067 Tipo de Serviço Fixo “20”
        primeira_linha << '1' #068 A 068 Código de origem do arquivo Fixo “1”
        primeira_linha << self.parametros.sequencial_arquivo_cobranca.to_s.rjust(5,"0")   # 069 a 073 numero sequencial de remessa
        primeira_linha << '00000' #074 A 078 - Número do retorno Campo válido somente para o arquivo retorno – fixo zeros 
        primeira_linha << Time.now.strftime('%Y%m%d').to_s.rjust(8,"0") # 079 a 086 data de gravaçao do arquivo 
        primeira_linha << Time.now.strftime('%H%M%S').to_s.rjust(6,"0") #087 A 092 -hora da gravacao do arquivo
        primeira_linha << ''.ljust(5,' ') #093 A 097 -  brancos
        primeira_linha << ''.ljust(3,' ') #098 A 100 -  brancos
        primeira_linha << ''.ljust(5,' ') #101 A 105 -  brancos
        primeira_linha << '0' #106 A 106 - Tipo de processamento - Preencher com 0
        primeira_linha << ''.ljust(74,' ') #107 A 180 - Reservado a empresa preencher com brancos
        primeira_linha << ''.ljust(80,' ') #181 A 260 - Reservado ao banco preencher com brancos
        primeira_linha << ''.ljust(217,' ') #361 A 477 - Reservado ao banco preencher com brancos
        primeira_linha << self.parametros.numero_da_lista_de_debito.to_s.rjust(9,'0') #478 A 486 - Numero da lista de debito
        primeira_linha << ''.ljust(8,' ') #487 A 494 - Reservado ao banco preencher com brancos
        primeira_linha << num_sequencia.to_s.rjust(6,"0") # 495 a 500 numero sequencial do registro de um em um 
        primeira_linha << "\n"
        p = self.parametros
        p.sequencial_arquivo_cobranca += 1
        p.numero_da_lista_de_debito += 1
        p.save 
        return primeira_linha
      end
      
      def cabecalho_arquivo_repasse
        primeira_linha = "0" #001 A 001 - Identificação do Registro - 001 -Obrigatório – fixo “zero”(0)
        primeira_linha << self.parametros.codigo_de_comunicacao.to_s.rjust(8,'0') # 002 A 009 - Código de Comunicação - 008 
        primeira_linha << '2' #010 A 010 -  Tipo de Inscrição da Empresa Pagadora - 1 = CPF / 2 = CNPJ / 3= OUTROS
        primeira_linha << self.parametros.cnpj_cedente.rjust(15,'0') #011 A 025 - CNPJ/CPF Base da Empresa Pagadora
        primeira_linha << I18n.transliterate(self.parametros.cedente)[0,40].ljust(40," ").upcase # 26 a 65 nome da empresa      
        primeira_linha << '20' #066 A 067 Tipo de Serviço Fixo “20”
        primeira_linha << '1' #068 A 068 Código de origem do arquivo Fixo “1”
        primeira_linha << self.parametros.sequencial_arquivo_cobranca.to_s.rjust(5,"0")   # 069 a 073 numero sequencial de remessa
        primeira_linha << '00000' #074 A 078 - Número do retorno Campo válido somente para o arquivo retorno – fixo zeros 
        primeira_linha << Time.now.strftime('%Y%m%d').to_s.rjust(8,"0") # 079 a 086 data de gravaçao do arquivo 
        primeira_linha << Time.now.strftime('%H%M%S').to_s.rjust(6,"0") #087 A 092 -hora da gravacao do arquivo
        primeira_linha << ''.ljust(5,' ') #093 A 097 -  brancos
        primeira_linha << ''.ljust(3,' ') #098 A 100 -  brancos
        primeira_linha << ''.ljust(5,' ') #101 A 105 -  brancos
        primeira_linha << '0' #106 A 106 - Tipo de processamento - Preencher com 0
        primeira_linha << ''.ljust(74,' ') #107 A 180 - Reservado a empresa preencher com brancos
        primeira_linha << ''.ljust(80,' ') #181 A 260 - Reservado ao banco preencher com brancos
        primeira_linha << ''.ljust(217,' ') #361 A 477 - Reservado ao banco preencher com brancos
        primeira_linha << self.parametros.numero_da_lista_de_debito.to_s.rjust(9,'0') #478 A 486 - Numero da lista de debito
        primeira_linha << ''.ljust(8,' ') #487 A 494 - Reservado ao banco preencher com brancos
        primeira_linha << num_sequencia.to_s.rjust(6,"0") # 495 a 500 numero sequencial do registro de um em um 
        primeira_linha << "\n"
        p = self.parametros
        p.sequencial_arquivo_cobranca += 1
        p.numero_da_lista_de_debito += 1
        p.save         
        return primeira_linha
      end
      
      def corpo_arquivo_remessa_fatura
        numero_de_registros = self.num_sequencia
        self.boletos.each do |boleto|
          numero_de_registros += 1
          linha = "1"
          linha << "00000"   # 2 a 6 agencia debito 
          linha << " "       # 7 a 7 digito agencia debito
          linha << "00000"   # 8 a 12 razão conta corrente
          linha << "0000000" # 13 a 19 conta corrente
          linha << " "       # 20 a 20 digito
          linha << "0"       # 21 a 21 zero
          linha << self.parametros.carteira_financeira.to_s.rjust(3,"0") # 22 a 24 codigo da carteira
          linha << self.parametros.agencia.rjust(5,"0")  # 25 a 29 agencia cedente sem digito
          linha << self.parametros.conta.rjust(7,"0")    # 30 a 36 conta corrente
          linha << self.parametros.conta_dv.to_s # 37 a 37 digito conta
          linha << "".rjust(25," ")      # 38 a 62 uso da empresa
          linha << "".rjust(3,"0")       # 63 a 65 codigo banco a ser debitado
          linha << "2".rjust(1,"0")      # 66 a 66 campo de multa
          linha << "0200".rjust(4,"0")   # 67 a 70 percentual de multa a ser considerado
          linha << boleto.id.to_s.rjust(11,"0")         # 71 a 81 identificação do titulo "tem que ser gerado automatico"
          linha << self.digito_verificador(self.parametros.carteira_financeira, boleto.id) # 82a82 digito de auto conferencia "tem que ser gerado automatico"
          linha << "".rjust(10,"0") # 83 a 92 desconto bonificação
          linha << "2" # 93 a 93 condição para emissão da papeleta
          linha << "N" # 94 a 94 identificação se emite papeleta para debito
          linha << "".ljust(10," ") # 95 a 104 identificação da operação do banco
          linha << " " # 105 a 105 indicador rateio
          linha << " " # 106 a 106 endereço para aviso
          linha << " ".ljust(2," ") # 107 a 108 branco
          linha << "01" # 109 a 110 identificacao da ocorrencia
          linha << boleto.id.to_s.ljust(10," ") # 111 a 120 num do documento "tem que ser gerado automatico"
          linha << boleto.vencimento.strftime('%d%m%y').rjust(6,"0")  # 121 a 126 data do vencimento do titulo
          linha << boleto.valor.contabil.gsub('.','').gsub(',','').rjust(13,"0") # 127 a 139 valor do titulo
          linha << "".rjust(3,"0")  # 140 a 142 banco encarregado da cobrança
          linha << "".rjust(5,"0")  # 143 a 147 agencia depositaria
          linha << "01" # 148 a 149 especie de titulo
          linha << "N"  # 150 a 150 identificação
          linha << boleto.created_at.strftime('%d%m%y').rjust(6,"0")  # 151 a 156 data da emissão do titulo "falta preencher"
          linha << "".rjust(2,"0")  # 157 a 158 1a instrução
          linha << "".rjust(2,"0")  # 159 a 160 2a instrução
          linha << (boleto.valor / 3000.0).contabil.gsub('.','').gsub(',','').rjust(13,"0") # 161 a 173 valor da cobrança por dia atraso "verificar o pecentual de cobrança"
          linha << "".rjust(6,"0")  # 174 a 179 Data Limite P/Concessão de Desconto
          linha << "".rjust(13,"0") # 180 a 192 Valor do Desconto
          linha << "".rjust(13,"0") # 193 a 205 Valor do IOF
          linha << "".rjust(13,"0") # 206 a 218 Valor do Abatimento a ser concedido ou cancelado
          linha << "02".rjust(2,"0")  # 219 a 220 identificação do tipo de incrição do sacado
          linha << boleto.fatura.cartorio.cnpj.gsub(/[^0-9]/,'').rjust(14,"0") # 221 a 234 incriçao do sacado
          linha << I18n.transliterate(boleto.fatura.cartorio.oficio)[0,40].gsub('º',' ').gsub('°',' ').upcase.ljust(40) #235 a 274 nome do sacado
          linha << "".ljust(40," ") # 275 a 314 end completo
          linha << "".ljust(12," ") # 315 a 326 1a menssagem
          linha << "".rjust(5,"0")  # 327 a 331 CEP
          linha << "".rjust(3,"0")  # 332 a 334 sufixo do CEP
          linha << "".ljust(60," ") # 335 a 394 sacador ou 2a menssagem
          linha << numero_de_registros.to_s.rjust(6,"0")  # 395 a 400 num sequencial do registro
          linha << "\n"
          @arquivo.write(linha)
        end
        return numero_de_registros
      end

      def corpo_arquivo_remessa_boleto(baixa_manual = false)
        numero_de_registros = self.num_sequencia
        self.boletos.each do |boleto|
          numero_de_registros += 1
          linha = "1"
          linha << "00000"   # 2 a 6 agencia debito 
          linha << " "       # 7 a 7 digito agencia debito
          linha << "00000"   # 8 a 12 razão conta corrente
          linha << "0000000" # 13 a 19 conta corrente
          linha << " "       # 20 a 20 digito
          linha << "0"       # 21 a 21 zero
          linha << self.parametros.carteira_boleto.to_s.rjust(3,"0") # 22 a 24 codigo da carteira
          linha << self.parametros.agencia.rjust(5,"0")  # 25 a 29 agencia cedente sem digito
          linha << self.parametros.conta.rjust(7,"0")    # 30 a 36 conta corrente
          linha << self.parametros.conta_dv.to_s # 37 a 37 digito conta
          linha << "".rjust(25," ")      # 38 a 62 uso da empresa
          linha << "".rjust(3,"0")       # 63 a 65 codigo banco a ser debitado
          linha << "0".rjust(1,"0")      # 66 a 66 campo de multa
          linha << "0000".rjust(4,"0")   # 67 a 70 percentual de multa a ser considerado
          linha << boleto.id.to_s.rjust(11,"0")         # 71 a 81 identificação do titulo "tem que ser gerado automatico"
          linha << self.digito_verificador(self.parametros.carteira_boleto, boleto.id) # 82 a 82 digito de auto conferencia "tem que ser gerado automatico"
          linha << "".rjust(10,"0") # 83 a 92 desconto bonificação
          linha << "2" # 93 a 93 condição para emissão da papeleta
          linha << "N" # 94 a 94 identificação se emite papeleta para debito
          linha << "".ljust(10," ") # 95 a 104 identificação da operação do banco
          linha << " " # 105 a 105 indicador rateio
          linha << " " # 106 a 106 endereço para aviso
          linha << " ".ljust(2," ") # 107 a 108 branco
          if boleto.reenviar_banco
            linha << "06" # 109 a 110 identificacao da ocorrencia
          elsif baixa_manual
            linha << "02" # 109 a 110 identificacao da ocorrencia
          else          
            linha << "01" # 109 a 110 identificacao da ocorrencia
          end
          linha << boleto.id.to_s.ljust(10," ") # 111 a 120 num do documento "tem que ser gerado automatico"
          linha << boleto.data_venc.strftime('%d%m%y').rjust(6,"0")  # 121 a 126 data do vencimento do titulo
          linha << boleto.val_boleto.contabil.gsub('.','').gsub(',','').rjust(13,"0") # 127 a 139 valor do titulo
          linha << "".rjust(3,"0")  # 140 a 142 banco encarregado da cobrança
          linha << "".rjust(5,"0")  # 143 a 147 agencia depositaria
          linha << "01" # 148 a 149 especie de titulo
          linha << "N"  # 150 a 150 identificação
          linha << boleto.created_at.strftime('%d%m%y').rjust(6,"0")  # 151 a 156 data da emissão do titulo "falta preencher"
          linha << "".rjust(2,"0")  # 157 a 158 1a instrução
          linha << "".rjust(2,"0")  # 159 a 160 2a instrução
          linha << "".rjust(13,"0") # 161 a 173 valor da cobrança por dia atraso "verificar o pecentual de cobrança"
          linha << "".rjust(6,"0")  # 174 a 179 Data Limite P/Concessão de Desconto
          linha << "".rjust(13,"0") # 180 a 192 Valor do Desconto
          linha << "".rjust(13,"0") # 193 a 205 Valor do IOF
          linha << "".rjust(13,"0") # 206 a 218 Valor do Abatimento a ser concedido ou cancelado
          linha << ( boleto.cpf.gsub(/[^0-9]/,'').size == 11 ? "01" : "02" )  # 219a220 identificação do tipo de incrição do sacado
          linha << boleto.cpf.gsub(/[^0-9]/,'').rjust(14,"0") # 221 a 234 incriçao do sacado
          linha << I18n.transliterate(boleto.financiado.nome)[0,40].gsub('º',' ').gsub('°',' ').upcase.ljust(40) #235 a 274 nome do sacado
          linha << "".ljust(40," ") # 275 a 314 end completo
          linha << "".ljust(12," ") # 315 a 326 1a menssagem
          linha << "".rjust(5,"0")  # 327 a 331 CEP
          linha << "".rjust(3,"0")  # 332 a 334 sufixo do CEP
          linha << "".ljust(60," ") # 335 a 394 sacador ou 2a menssagem
          linha << numero_de_registros.to_s.rjust(6,"0")  # 395 a 400 num sequencial do registro
          linha << "\n"
          @arquivo.write(linha)
        end
        return numero_de_registros
      end

      def corpo_pagamento_estorno
        numero_de_registros = self.num_sequencia
        self.objeto.ressarcimentos.each do |ressarcimento|
          if ressarcimento.valor >= 0.01
            numero_de_registros += 1
            informacoes_complementares = (ressarcimento.cod_banco == '237' ? ''.ljust(40,' ') : "C000000010#{ressarcimento.tipo_conta}".ljust(40,' ') )
            ## trata formatacao do cpf e cnpj para arquivo
            vcpf = ressarcimento.cpf_cnpj_favorecido.gsub(/[^0-9]/,'')
            if vcpf.size == 11
              vcpf = vcpf[0,9] + '0000' + vcpf[9,2]
            end   
            linha = "1"
            linha << ressarcimento.tipo_inscricao.to_s # 002 A 002 - Tipo de inscricao do Fornecedor - 1- CPF, 2- CNPJ, 3-OUtros
            linha << vcpf.rjust(15,'0') #003 A 017 - CPF/CNPJ fornecedor
            linha << I18n.transliterate(ressarcimento.favorecido)[0,30].gsub('º',' ').gsub('°',' ').upcase.ljust(30) #018 A 047 - Nome do fornecedor
            #linha << I18n.transliterate(ressarcimento.endereco)[0,40].gsub('º',' ').gsub('°',' ').upcase.ljust(40,' ') # 048 A 087 Endereco do fornecedor
            #linha << ressarcimento.cep #088 A 095 -  Cep do fornecedor
            linha << 'RUA WALTER BEZERRA DE SA 55'.ljust(40,' ') # 048 A 087 Endereco do fornecedor
            linha << '60135225' #088 A 095 -  Cep do fornecedor      
            linha << ressarcimento.cod_banco.rjust(3,'0') #096 A 098 - Codigo do banco do fornecedor
            linha << ressarcimento.agencia.rjust(5,'0') # 099 A 103 - Codigo da agencia do fornecedor
            linha << ressarcimento.digito_agencia.ljust(1,' ') # 104 A 104 - digito da agencia do fornecedor
            linha << ressarcimento.conta_corrente.rjust(13,'0') # 105 A 117 - conta ocrrente do fornecedor
            linha << ressarcimento.digito_conta.ljust(2,' ') #118 A 119 - digito da conta corrente do fornecedor
            linha << ressarcimento.numero_pagamento.ljust(16,' ') #120 A 135 - Número do Pagamento.
            linha << '000' #136 A 138 - Carteira - fixo 000
            linha << ''.rjust(12,'0') #139 A 150 - Nosso numero - fixo 0
            linha << ''.rjust(15,'0') #151 A 165 - Seu numero - fixo 0
            linha << Date.today.strftime('%Y%m%d').rjust(8,'0') #166 A 173 # data de vencimento
            linha << ''.rjust(8,'0') #174 A 181 # data de emissao - fixo 0
            linha << ''.rjust(8,'0') #182 A 189 # data limite para desconto - fixo 0
            linha << '0' #190 A 190 - Fixo 0
            linha << '0'.rjust(4,'0') #191 A 194 - Fator de vencimento - fixo 0
            linha << '0'.rjust(10,'0') #195 A 204 - Valor do Documento - fixo 0
            linha << ressarcimento.valor.contabil.gsub('.','').gsub(',','').rjust(15,'0') # 205 A 219 # valor do pagamento
            linha << '0'.rjust(15,'0') #220 A 234 - Valor do desconto - fixo 0
            linha << '0'.rjust(15,'0') #235 A 249 - Valor do acrescimo - fixo 0 
            linha << '05' #250 A 251 - Tipo de documento - 05 = OUTROS
            linha << '0'.rjust(10,'0') #252 A 261 - Numero nota fiscal - fixo 0
            linha << '  ' #262 A 263 - serie do documento - opicional 
            linha << (ressarcimento.cod_banco == '237' ? '05' : '03' ) #264 A 265 - modalidade de pagamento - 01 = transf, 03 = doc
            linha << Date.today.strftime('%Y%m%d').rjust(8,"0") #266 A 273 # data para efetivacao do pagmento
            linha << ''.ljust(3,' ') # 274 A 276 - Moeda - Fixo Branco
            linha << '01' # 277 a 278 - Situação do Agendamento - Fixo 01
            linha << ''.ljust(10,' ') #279 A 288 - Informacao de retorno - fixo branco
            linha << '0' # 289 A 289 - Tipo de movimento - 0 = inclusao
            linha << '25' # 290 A 291 - Codigo do movimento - 25 = autoriza agendamento
            linha << ''.ljust(4,' ') # 292 A 295 - Horario para consulta de saldo - fixo branco
            linha << ''.ljust(15,' ')# 296 A 310 - Saldo disponivel - fixo branco
            linha << ''.ljust(15,' ')# 311 A 325 - Valor da taxa pre-funding - fixo branco  
            linha << ''.ljust(6,' ') # 326 A 331 - fixo brancos
            linha << ''.ljust(40,' ') # 332 A 371 - Sacador avalista  somente para titulos em cobranca - fixo brancos
            linha << ' '#372 A 372 - Fixo Branco
            linha << ' '#373 A 373 - Nivel da informacao do retorno - Fixo Branco
            linha << informacoes_complementares #374 a 413 # informacoes complementares
            linha << '00' #414 A 415 - codigo de area na empresa - opcional
            linha << ''.ljust(35,' ') # 416 A 450 - Para uso da empresa - fixo branco
            linha << ''.ljust(22,' ') # 451 A 472 - Fixo Brancos
            linha << ressarcimento.id.to_s.rjust(5,'0')   #473 A 477 - Codigo de lancamento
            linha << ' ' # 478 A 478 reserva - fixo branco
            linha << ressarcimento.tipo_conta.to_s #479 A 479 - Tipo de conta do fornecedor - 1 = conta corrente, 2= conta poupanca
            linha << self.parametros.conta.rjust(7,'0') #480 A 486 - Conta complementar - Fixo 0
            linha << ''.ljust(8,' ') # 487 A 494 - fixo branco
            linha << numero_de_registros.to_s.rjust(6,'0')  # 495 a 500 num sequencial do registro
            linha << "\n"
            @arquivo.write(linha)
          end
        end
        return numero_de_registros
      end

      def corpo_arquivo_repasse
        numero_de_registros = self.num_sequencia
        self.objeto.itens_repasses.each do |item_repasse|
          if item_repasse.valor >= 0.01
            numero_de_registros += 1
            informacoes_complementares = (item_repasse.cartorio.dado_cartorario.codigo_banco == '237' ? ''.ljust(40,' ') : "C000000010#{item_repasse.cartorio.dado_cartorario.tipo_conta}".ljust(40,' ') )
            ## trata formatacao do cpf e cnpj para arquivo
            vcpf = item_repasse.cartorio.dado_cartorario.cpf_cnpj.gsub(/[^0-9]/,'')
            if vcpf.size == 11
              vcpf = vcpf[0,9] + '0000' + vcpf[9,2]
            end   
            linha = "1"
            linha << item_repasse.cartorio.dado_cartorario.tipo_de_inscricao.to_s # 002 A 002 - Tipo de inscricao do Fornecedor - 1- CPF, 2- CNPJ, 3-OUtros
            linha << vcpf.rjust(15,'0') #003 A 017 - CPF/CNPJ fornecedor
            linha << I18n.transliterate(item_repasse.cartorio.dado_cartorario.nome)[0,30].gsub('º',' ').gsub('°',' ').upcase.ljust(30) #018 A 047 - Nome do fornecedor
            linha << I18n.transliterate(item_repasse.cartorio.dado_cartorario.endereco)[0,40].gsub('º',' ').gsub('°',' ').upcase.ljust(40,' ') # 048 A 087 Endereco do fornecedor
            linha << item_repasse.cartorio.dado_cartorario.cep.gsub('.','').gsub('-','') #088 A 095 -  Cep do fornecedor
            linha << item_repasse.cartorio.dado_cartorario.codigo_banco.rjust(3,'0') #096 A 098 - Codigo do banco do fornecedor
            linha << item_repasse.cartorio.dado_cartorario.codigo_agencia.rjust(5,'0') # 099 A 103 - Codigo da agencia do fornecedor
            linha << item_repasse.cartorio.dado_cartorario.digito_agencia.ljust(1,' ') # 104 A 104 - digito da agencia do fornecedor
            linha << item_repasse.cartorio.dado_cartorario.conta_corrente.rjust(13,'0') # 105 A 117 - conta ocrrente do fornecedor
            linha << item_repasse.cartorio.dado_cartorario.digito_conta_corrente.ljust(2,' ') #118 A 119 - digito da conta corrente do fornecedor
            linha << ItemRepasse.numero_pagamento.to_s.ljust(16,' ') #120 A 135 - Número do Pagamento.
            linha << '000' #136 A 138 - Carteira - fixo 000
            linha << ''.rjust(12,'0') #139 A 150 - Nosso numero - fixo 0
            linha << ''.rjust(15,'0') #151 A 165 - Seu numero - fixo 0
            linha << item_repasse.repasse.data_vencimento.strftime('%Y%m%d').rjust(8,'0') #166 A 173 # data de vencimento
            linha << ''.rjust(8,'0') #174 A 181 # data de emissao - fixo 0
            linha << ''.rjust(8,'0') #182 A 189 # data limite para desconto - fixo 0
            linha << '0' #190 A 190 - Fixo 0
            linha << '0'.rjust(4,'0') #191 A 194 - Fator de vencimento - fixo 0
            linha << '0'.rjust(10,'0') #195 A 204 - Valor do Documento - fixo 0
            linha << item_repasse.valor.contabil.gsub('.','').gsub(',','').rjust(15,'0') # 205 A 219 # valor do pagamento
            linha << '0'.rjust(15,'0') #220 A 234 - Valor do desconto - fixo 0
            linha << '0'.rjust(15,'0') #235 A 249 - Valor do acrescimo - fixo 0 
            linha << '05' #250 A 251 - Tipo de documento - 05 = OUTROS
            linha << '0'.rjust(10,'0') #252 A 261 - Numero nota fiscal - fixo 0
            linha << '  ' #262 A 263 - serie do documento - opicional 
            linha << (item_repasse.cartorio.dado_cartorario.codigo_banco == '237' ? '05' : '03' ) #264 A 265 - modalidade de pagamento - 01 = transf, 03 = doc
            linha << item_repasse.repasse.data_vencimento.strftime('%Y%m%d').rjust(8,"0") #266 A 273 # data para efetivacao do pagmento
            linha << ''.ljust(3,' ') # 274 A 276 - Moeda - Fixo Branco
            linha << '01' # 277 a 278 - Situação do Agendamento - Fixo 01
            linha << ''.ljust(10,' ') #279 A 288 - Informacao de retorno - fixo branco
            linha << '0' # 289 A 289 - Tipo de movimento - 0 = inclusao
            linha << '25' # 290 A 291 - Codigo do movimento - 25 = autoriza agendamento
            linha << ''.ljust(4,' ') # 292 A 295 - Horario para consulta de saldo - fixo branco
            linha << ''.ljust(15,' ')# 296 A 310 - Saldo disponivel - fixo branco
            linha << ''.ljust(15,' ')# 311 A 325 - Valor da taxa pre-funding - fixo branco  
            linha << ''.ljust(6,' ') # 326 A 331 - fixo brancos
            linha << ''.ljust(40,' ') # 332 A 371 - Sacador avalista  somente para titulos em cobranca - fixo brancos
            linha << ' '#372 A 372 - Fixo Branco
            linha << ' '#373 A 373 - Nivel da informacao do retorno - Fixo Branco
            linha << informacoes_complementares #374 a 413 # informacoes complementares
            linha << '00' #414 A 415 - codigo de area na empresa - opcional
            linha << ''.ljust(35,' ') # 416 A 450 - Para uso da empresa - fixo branco
            linha << ''.ljust(22,' ') # 451 A 472 - Fixo Brancos
            linha << (item_repasse.id - 167000).to_s.slice(0,5).rjust(5,'0')   #473 A 477 - Codigo de lancamento
            linha << ' ' # 478 A 478 reserva - fixo branco
            linha << item_repasse.cartorio.dado_cartorario.tipo_conta.to_s #479 A 479 - Tipo de conta do fornecedor - 1 = conta corrente, 2= conta poupanca
            linha << self.parametros.conta.rjust(7,'0') #480 A 486 - Conta complementar - Fixo 0
            linha << ''.ljust(8,' ') # 487 A 494 - fixo branco
            linha << numero_de_registros.to_s.rjust(6,'0')  # 495 a 500 num sequencial do registro
            linha << "\n"
            @arquivo.write(linha)
          end
        end
        return numero_de_registros
      end

     def corpo_arquivo_fornecedor
        numero_de_registros = self.num_sequencia
        self.objeto.pagamentos_fornecedores.each do |pagamento|
          if pagamento.valor >= 0.01
            fornecedor = pagamento.fornecedor
            numero_de_registros += 1
            informacoes_complementares = (fornecedor.cod_banco == '237' ? ''.ljust(40,' ') : "C000000010#{fornecedor.tipo_de_conta}".ljust(40,' ') )
            vcpf = fornecedor.cpf_cnpj.gsub(/[^0-9]/,'')
            if vcpf.size == 11
              tipo_inscricao = 1
              vcpf = vcpf[0,9] + '0000' + vcpf[9,2]
            else
              tipo_inscricao = 2
            end   
            linha = "1"
            linha << tipo_inscricao.to_s # 002 A 002 - Tipo de inscricao do Fornecedor - 1- CPF, 2- CNPJ, 3-OUtros
            linha << vcpf.rjust(15,'0') #003 A 017 - CPF/CNPJ fornecedor
            linha << I18n.transliterate(fornecedor.razao_social)[0,30].gsub('º',' ').gsub('°',' ').upcase.ljust(30) #018 A 047 - Nome do fornecedor
            linha << I18n.transliterate(fornecedor.logradouro)[0,40].gsub('º',' ').gsub('°',' ').upcase.ljust(40,' ') # 048 A 087 Endereco do fornecedor
            linha << fornecedor.cep.gsub('.','').gsub('-','') #088 A 095 -  Cep do fornecedor
            linha << fornecedor.cod_banco.rjust(3,'0') #096 A 098 - Codigo do banco do fornecedor
            linha << fornecedor.agencia.rjust(5,'0') # 099 A 103 - Codigo da agencia do fornecedor
            linha << fornecedor.digito_agencia.ljust(1,' ') # 104 A 104 - digito da agencia do fornecedor
            linha << fornecedor.conta.rjust(13,'0') # 105 A 117 - conta ocrrente do fornecedor
            linha << fornecedor.digito_conta.ljust(2,' ') #118 A 119 - digito da conta corrente do fornecedor
            linha << pagamento.id.to_s.ljust(16,' ') #120 A 135 - Número do Pagamento.
            linha << '000' #136 A 138 - Carteira - fixo 000
            linha << ''.rjust(12,'0') #139 A 150 - Nosso numero - fixo 0
            linha << ''.rjust(15,'0') #151 A 165 - Seu numero - fixo 0
            linha << Date.today.strftime('%Y%m%d').rjust(8,'0') #166 A 173 # data de vencimento
            linha << ''.rjust(8,'0') #174 A 181 # data de emissao - fixo 0
            linha << ''.rjust(8,'0') #182 A 189 # data limite para desconto - fixo 0
            linha << '0' #190 A 190 - Fixo 0
            linha << '0'.rjust(4,'0') #191 A 194 - Fator de vencimento - fixo 0
            linha << '0'.rjust(10,'0') #195 A 204 - Valor do Documento - fixo 0
            linha << pagamento.valor.contabil.gsub('.','').gsub(',','').rjust(15,'0') # 205 A 219 # valor do pagamento
            linha << '0'.rjust(15,'0') #220 A 234 - Valor do desconto - fixo 0
            linha << '0'.rjust(15,'0') #235 A 249 - Valor do acrescimo - fixo 0 
            linha << '05' #250 A 251 - Tipo de documento - 05 = OUTROS
            linha << '0'.rjust(10,'0') #252 A 261 - Numero nota fiscal - fixo 0
            linha << '  ' #262 A 263 - serie do documento - opicional 
            linha << (fornecedor.cod_banco == '237' ? '05' : '03' ) #264 A 265 - modalidade de pagamento - 01 = transf, 03 = doc
            linha << Date.today.strftime('%Y%m%d').rjust(8,"0") #266 A 273 # data para efetivacao do pagmento
            linha << ''.ljust(3,' ') # 274 A 276 - Moeda - Fixo Branco
            linha << '01' # 277 a 278 - Situação do Agendamento - Fixo 01
            linha << ''.ljust(10,' ') #279 A 288 - Informacao de retorno - fixo branco
            linha << '0' # 289 A 289 - Tipo de movimento - 0 = inclusao
            linha << '25' # 290 A 291 - Codigo do movimento - 25 = autoriza agendamento
            linha << ''.ljust(4,' ') # 292 A 295 - Horario para consulta de saldo - fixo branco
            linha << ''.ljust(15,' ')# 296 A 310 - Saldo disponivel - fixo branco
            linha << ''.ljust(15,' ')# 311 A 325 - Valor da taxa pre-funding - fixo branco  
            linha << ''.ljust(6,' ') # 326 A 331 - fixo brancos
            linha << ''.ljust(40,' ') # 332 A 371 - Sacador avalista  somente para titulos em cobranca - fixo brancos
            linha << ' '#372 A 372 - Fixo Branco
            linha << ' '#373 A 373 - Nivel da informacao do retorno - Fixo Branco
            linha << informacoes_complementares #374 a 413 # informacoes complementares
            linha << '00' #414 A 415 - codigo de area na empresa - opcional
            linha << ''.ljust(35,' ') # 416 A 450 - Para uso da empresa - fixo branco
            linha << ''.ljust(22,' ') # 451 A 472 - Fixo Brancos
            linha << pagamento.id.to_s.rjust(5,'0')   #473 A 477 - Codigo de lancamento
            linha << ' ' # 478 A 478 reserva - fixo branco
            linha << fornecedor.tipo_de_conta.to_s #479 A 479 - Tipo de conta do fornecedor - 1 = conta corrente, 2= conta poupanca
            linha << self.parametros.conta.rjust(7,'0') #480 A 486 - Conta complementar - Fixo 0
            linha << ''.ljust(8,' ') # 487 A 494 - fixo branco
            linha << numero_de_registros.to_s.rjust(6,'0')  # 495 a 500 num sequencial do registro
            linha << "\n"
            @arquivo.write(linha)
          end
        end
        return numero_de_registros
      end

      def rodape_arquivo_remessa(numero_de_registros)
        numero_de_registros += 1
        linha_rodape = "9" # identificacao do registro
        linha_rodape << "".ljust(393," ") # branco
        linha_rodape << numero_de_registros.to_s.rjust(6,"0") # 395 a 400 numero sequencial do registro de um em um 
        linha_rodape << "\n"
        return linha_rodape
      end

      def rodape_pagamento_estorno(numero_de_registros)
        numero_de_registros += 1
        linha_rodape = '9' # 001 A 001 - fixo 9
        linha_rodape << numero_de_registros.to_s.rjust(6,'0') # 002 A 007 - quantidade de registros incluindo o header e o proprio trailer
        linha_rodape << self.objeto.valor.contabil.gsub('.','').gsub(',','').rjust(17,"0") # 008 A 024 - Valor dos registros
        linha_rodape << ''.ljust(470,' ') # 025 A 494 # fixo branco
        linha_rodape << numero_de_registros.to_s.rjust(6,"0")  # 495 a 500 num sequencial do registro
        linha_rodape << "\n"
        return linha_rodape        
      end
      
      def rodape_arquivo_repasse(numero_de_registros)
        numero_de_registros += 1
        linha_rodape = '9' # 001 A 001 - fixo 9
        linha_rodape << numero_de_registros.to_s.rjust(6,'0') # 002 A 007 - quantidade de registros incluindo o header e o proprio trailer
        linha_rodape << self.objeto.valor.contabil.gsub('.','').gsub(',','').rjust(17,"0") # 008 A 024 - Valor dos registros
        linha_rodape << ''.ljust(470,' ') # 025 A 494 # fixo branco
        linha_rodape << numero_de_registros.to_s.rjust(6,"0")  # 495 a 500 num sequencial do registro
        linha_rodape << "\n"
        return linha_rodape    
      end
      
      def retira_acentos(texto) 
        retorno = texto.upcase.gsub('º','o').gsub('ª','a').gsub('Á','A').gsub('À','A').gsub('Ã','A').gsub('Â','A').gsub('É','E').gsub('È','E').gsub('Ê','E').gsub('Í','I').gsub('Ì','I').gsub('Î','I').gsub('Ó','O').gsub('Ò','O').gsub('Ô','O').gsub('Õ','O').gsub('Ú','U').gsub('Ù','U').gsub('Û','U').gsub('Ü','U').gsub('Ç','C').gsub(' ','o ')
      end

      def digito_verificador(carteira, nosso_numero)
        carteira     = carteira.to_s.rjust(2,'0')
        nosso_numero = nosso_numero.to_s.rjust(11,'0')
        base = carteira + nosso_numero
        #inverte a posicao dos numeros
        base.reverse!
        base = base.split('')

        #incia o calculo
        fator = 1
        soma = 0
        for x in base
         if fator < 7
           fator += 1 
         else
           fator = 2
         end
         soma += (fator * x.to_f)
        end
        resto = (soma % 11)
        if resto == 1 
         dv = 'P'
        elsif resto == 0
         dv = '0'
        else
        dv = (11 - resto.to_i).to_s
        end   
        dv
      end


    end
  end
end
