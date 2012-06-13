# Makefile padrão para projetos LaTeX
# Autor: Paulo Roberto Urio (paulourio gmail com)
# Licença: FreeBSD

# Nome do arquivo principal do seu projeto
# Não coloque com a extensão do arquivo. Se for "trab.tex": MAIN=trab
MAIN=article
# Nome completo do arquivo de referências (com a extensão).  Pode ser utilizado
# caminho relativo como BIB=../../bibliografia.bib
BIB=data/references.bib
# Comportamento padrão para o comando make sem argumentos.
# Possibilidades: 
#   try_all     Tenta gerar com bibliografia.  Se o arquivo não
#               existir o alvo será redirecionado para 'pdf'
#   pdf         Executa apenas o alvo PDF por padrão.
# Veja 'make help' para mais opções de alvos.
default: try_all

#-------------------------------------------------------------------------------
SHELL=/bin/bash
LATEX=pdflatex -interaction=nonstopmode -shell-escape
LATEX_DEBUG=pdflatex\ -file-line-error\ -interaction=nonstopmode\ -shell-escape
BIBTEX=bibtex
MAKEFLAGS += --no-print-directory
V=0
.PHONY += default pdf $(MAIN) $(BIB) bib distclean clean _main help all try_all
PROGRESS=$(MAIN).mpgs
ERRO=\033[1m[\033[31;1mErro\033[0;1m]\033[0m
FATAL=\033[1m[\033[31;1mErro Fatal\033[0;1m]\033[0m
AVISO=\033[1m[\033[33;1mAviso\033[0;1m]\033[0m
INFO=\033[1m[\033[34;1mDebug\033[0;1m]\033[0m

export TEXINPUTS=$(shell kpsepath tex):$(shell pwd)/data/

try_all:
	@if [ -e $(BIB) ]; then \
		make all; \
	else \
		echo -e "$(AVISO) Arquivo $(BIB)"\
			 "não encontrado: executando apenas alvo pdf";\
		make pdf;\
	fi

debug:
	@echo -e "$(INFO) 0% - Gerando PDF"
	@sleep 0.3
	@make LATEX=$(LATEX_DEBUG) V=1 _main
	@echo -e "$(INFO) 25% - Gerando bibliografia"
	@if [ -e $(BIB) ]; then \
		sleep 0.3;\
		make LATEX=$(LATEX_DEBUG) V=1 bib;\
	else \
		echo -e "$(AVISO) Arquivo $(BIB)"\
			 "não encontrado. Ignorando...";\
		sleep 1;\
	fi	
	@echo -e "$(INFO) 50% - Gerando PDF"
	@sleep 0.3
	@make LATEX=$(LATEX_DEBUG) V=1 _main
	@echo -e "$(INFO) 75% - Gerando PDF (2)"
	@sleep 0.3
	@make LATEX=$(LATEX_DEBUG) V=1 _main
	@echo -e "$(INFO) 99% - Removendo arquivos temporários"
	@make LATEX=$(LATEX_DEBUG) V=1 clean
	@echo -e "$(INFO) 100% - PDF gerado.  Tamanho: `du -h $(MAIN).pdf | sed 's/\t/\tNome:\ /'`"

all: 
	@echo 0 > $(PROGRESS)
	@make bib
	@echo 35 > $(PROGRESS)
	@make _main
	@echo 65 > $(PROGRESS)
	@make _main
	@echo 90 > $(PROGRESS)
	@make clean
	@echo -e "\033[2K\r100%  Tamanho: `du -h $(MAIN).pdf | sed 's/\t/\tNome:\ /'`"

pdf:
	@echo 0 > $(PROGRESS)
	@make _main
	@echo 50 > $(PROGRESS)
	@make _main
	@echo 90 > $(PROGRESS)
	@make clean
	@echo -e "\033[2K\r100%  Tamanho: `du -h $(MAIN).pdf | sed 's/\t/\tNome:\ /'`"

_main: $(MAIN)

$(MAIN):
ifeq ($(V),0)
	@if [ ! -f $(MAIN).tex ]; then \
		echo -e "\n$(ERRO) Arquivo $(MAIN).tex não existe.";\
		echo -e "Edite o início do Makefile para definir o nome do"\
			 "arquivo TeX principal.";\
		false;\
	fi;
	@($(LATEX) $(MAIN) > /dev/null & latexpid=$$!; \
		(while [ -d "/proc/$$latexpid" ] ; do \
			echo -e "$$(($$(cat $(PROGRESS)) + 3))" > $(PROGRESS); \
			echo -en "\033[2K\r`cat $(PROGRESS)`%"; ex=$$?; \
			sleep 0.08; done &); \
			wait $$latexpid; exit $$?) || (\
		echo -e "\n$(ERRO)  Erro ao gerar PDF";\
		sleep 0.4;\
		echo -e "$(INFO) Entrando em modo debug";\
		sleep 0.6;\
		make debug; make clean; false)
else
	@($(LATEX) $(MAIN) || echo "$$?">$(MAIN).err) | \
		sed -r "s/^(.*)\:([0-9]+)\:/\n`printf "$(ERRO)"` `printf "\033[1m"`\1`printf "\033[0m"` linha `printf "\033[1m"`\2`printf "\033[0m"`:/g" |\
		sed -r "s/\(([^ ^\)]+\.tex)\)? ?/\n`printf "$(INFO)\033[32m"` Processando arquivo \1`printf "\033[0m"`\n/g" |\
		sed -r "s/Package (.*) Warning: ?/`printf "$(AVISO)"` \1: /g" |\
		sed -r "s/LaTeX Warning:/\n`printf "$(AVISO)"`/g" |\
		sed -r "s/! File ended while/\n`printf "$(ERRO)"` File ended while/g" |\
		sed -r "s/LaTeX Error:/\n`printf "$(ERRO)"`/g" |\
		sed -r "s/! Emergency stop./`printf "$(AVISO)"` Parada de emergência./g" |\
		sed -r "s/(==> Fatal error occurred, ?)(.*)/\n`printf "$(FATAL)"` \2./g" |\
		grep -E '(Aviso)|(Erro)|(Debug)' | grep -v 'Citation' | grep -v 'texmf'
	@if [ -f $(MAIN).err ]; then echo -e "$(INFO) Parando (código = `cat $(MAIN).err`).";\
		make clean; false; fi
endif

$(BIB):
	@echo -e "$(ERRO) Arquivo $(BIB) não encontrado.\033[0m"
	@make help
	@false

bib: $(BIB) _main
ifeq ($(V),0)
	@$(BIBTEX) $(MAIN) > /dev/null || (\
		echo -e "\n$(ERRO)  Erro ao gerar bibliografia\033[0m";\
		sleep 1;\
		echo -e "$(INFO) Entrando em modo debug";\
		sleep 2;\
		make debug; make clean; false)
else
	$(BIBTEX) $(MAIN) 
endif

distclean: clean
	@$(RM) *.pdf

clean:
	@$(RM) *.aux *.bbl *.blg *.dat *.dvi *.gnuplot *.log *.nav
	@$(RM) *.out *.snm *.toc *.vrb *.err *.mpgs *.table

help:
	@echo "Comandos:"
	@echo "    make            Gerar alvo padrão (veja 'default' no Makefile)"
	@echo "    make all        Gerar PDF com bibliografia"
	@echo "    make debug      Gerar PDF com bibliografia no modo interativo"
	@echo "    make pdf        Gerar apenas o PDF"
	@echo "    make clean      Apagar arquivos gerados"
	@echo "    make distclean  clean + apagar PDF gerado"
	@echo "Configuração:"
	@echo "    Este Makefile trabalha com apenas um arquivo .tex e um .bib"
	@echo "    Você precisa editar o arquivo Makefile para definir estes arquivos."

