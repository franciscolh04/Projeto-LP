% 106970 - Francisco Lourenco Heleno
:- set_prolog_flag(answer_write_options,[max_depth(0)]). % para listas completas
:- ['dados.pl'], ['keywords.pl']. % ficheiros a importar.

/*
eventosSemSalas(EventosSemSala) e verdade se EventosSemSala e uma lista, ordenada
e sem elementos repetidos, de IDs de eventos sem sala.
*/
eventosSemSalas(EventosSemSala) :-
    findall(ID, evento(ID, _, _, _, semSala), Eventos),
    sort(Eventos, EventosSemSala).


/*
eventosSemSalasDiaSemana(DiaDaSemana, EventosSemSala) e verdade se EventosSemSala
e uma lista, ordenada e sem elementos repetidos, de IDs de eventos sem sala que 
decorrem em DiaDaSemana.
*/
eventosSemSalasDiaSemana(DiaDaSemana, EventosSemSala) :-
    findall(ID, (horario(ID, DiaDaSemana, _, _, _, _), evento(ID, _, _, _, semSala)), Eventos),
    sort(Eventos, EventosSemSala).


/*
periodo_aux(Periodo, Semestre) e verdade se Semestre e o semestre no qual ocorre
o periodo Periodo.
*/
periodo_aux(Periodo, p1_2) :- member(Periodo, [p1, p2]).
periodo_aux(Periodo, p3_4) :- member(Periodo, [p3, p4]).


/*
eventosSemSalasPeriodo(ListaPeriodos, EventosSemSala) e verdade se ListaPeriodos e
uma lista de periodos(p1,p2,p3,p4) e EventosSemSala e uma lista, ordenada e sem
elementos repetidos, de IDs de eventos sem sala nos periodos de ListaPeriodos. 
O predicado contabiliza tambem os eventos sem salas associados a disciplinas semestrais,
isto e, p1_2 e p3_4.
*/
eventosSemSalasPeriodo([], []).
eventosSemSalasPeriodo([Periodo|RestantesPeriodos], EventosSemSala) :-
    % Percorre ListaPeriodos e analisa cada um dos periodos separadamente, pelo predicado auxiliar
    eventosSemSalasPeriodoAux(Periodo, EventosSemSalasPeriodo),
    eventosSemSalasPeriodo(RestantesPeriodos, RestantesEventosSemSalas),
    % Junta todos os eventos encontrados numa lista e ordena-a
    append(EventosSemSalasPeriodo, RestantesEventosSemSalas, EventosSemSalaNaoOrd),
    sort(EventosSemSalaNaoOrd, EventosSemSala).
% Predicado auxiliar para encontrar os eventos sem sala de cada periodo da lista fornecida.
eventosSemSalasPeriodoAux(Periodo, EventosSemSala) :-
    periodo_aux(Periodo, Semestre), !,
    % Procura eventos sem sala no periodo Periodo e respetivo semestre e adiciona-os a duas listas
    findall(ID, (evento(ID, _, _, _, semSala), horario(ID, _, _, _, _, Periodo)), EventosPeriodo),
    findall(ID, (evento(ID, _, _, _, semSala), horario(ID, _, _, _, _, Semestre)), EventosSemestre),
    % Junta as duas listas obtidas numa so e ordena-a
    append(EventosPeriodo, EventosSemestre, Eventos),
    sort(Eventos, EventosSemSala).


/*
organizaEventos(ListaEventos, Periodo, EventosNoPeriodo) e verdade se EventosNoPeriodo
e a lista, ordenada e sem elementos repetidos, de IDs dos eventos de ListaEventos que 
ocorrem no periodo Periodo.
*/
organizaEventos(ListaEventos, Periodo, EventosNoPeriodo) :-
    organizaEventosAux(ListaEventos, Periodo, EventosNoPeriodoAux),
    % Ordena a lista obtida pelo predicado auxiliar dando origem a lista final
    sort(EventosNoPeriodoAux, EventosNoPeriodo).
% Predicado auxiliar para verificar individualmente cada evento pertencente a ListaEventos.
organizaEventosAux([], _, []).
organizaEventosAux([Evento|RestantesEventos], Periodo, [Evento|EventosNoPeriodo]) :-
    periodo_aux(Periodo, Semestre),
    % Verifica se o evento ocorre no periodo especificado
    (horario(Evento, _, _, _, _, Periodo);
    horario(Evento, _, _, _, _, Semestre)), !,
    % Realiza o mesmo procedimento para os restantes eventos da lista
    organizaEventosAux(RestantesEventos, Periodo, EventosNoPeriodo).
% Caso o evento nao ocorra no periodo em conta
organizaEventosAux([_|RestantesEventos], Periodo, EventosNoPeriodo) :-
    organizaEventosAux(RestantesEventos, Periodo, EventosNoPeriodo).


/*
eventosMenoresQue(Duracao, ListaEventosMenoresQue) e verdade se ListaEventosMenoresQue
e a lista ordenada e sem elementos repetidos dos identificadores dos eventos que tem
duracao menor ou igual a Duracao.
*/
eventosMenoresQue(Duracao, ListaEventosMenoresQue) :-
    findall(ID, (horario(ID, _, _, _, DuracaoEvento, _), DuracaoEvento =< Duracao), Eventos),
    sort(Eventos, ListaEventosMenoresQue).


/*
eventosMenoresQueBool(ID, Duracao) e verdade se o evento identificado por ID tiver
duracao igual ou menor a Duracao.
*/
eventosMenoresQueBool(Evento, Duracao) :-
    horario(Evento, _, _, _, DuracaoEvento, _),
    DuracaoEvento =< Duracao.


/*
procuraDisciplinas(Curso, ListaDisciplinas) e verdade se ListaDisciplinas e a lista
ordenada alfabeticamente do nome das disciplinas do curso Curso.
*/
procuraDisciplinas(Curso, ListaDisciplinas) :-
    findall(Disciplina, (evento(ID, Disciplina, _, _, _), turno(ID, Curso, _, _)), Disciplinas),
    sort(Disciplinas, ListaDisciplinas).


/*
organizaDisciplinas(ListaDisciplinas, Curso, Semestres) e verdade se Semestres e uma
lista com duas listas ordenadas alfabeticamente e sem elementos repetidos, onde a lista
na primeira posicao contem as disciplinas de ListaDisciplinas do curso Curso que ocorrem
no primeiro semestre e a lista na segunda posicao contem as que ocorrem no segundo semestre.
O predicado falha se nao existir no curso Curso uma disciplina de ListaDisciplinas. 
*/
organizaDisciplinas(ListaDisciplinas, Curso, Semestres) :-
    % Verifica se todas as disciplinas da lista existem no curso
    disciplinasCurso(ListaDisciplinas, Curso),
    % Cria duas listas correspondentes as disciplinas da lista que ocorrem em cada um dos semestres
    organizaDisciplinasPrimSem(ListaDisciplinas, Curso, PrimSem),
    organizaDisciplinasSegSem(ListaDisciplinas, Curso, SegSem),
    % Retira da lista de disciplinas do segundo semestre, as que tambem ocorrem no primeiro
    subtract(SegSem, PrimSem, SegSemNaoRepetido),
    % Cria uma lista de listas, utilizando as duas listas obtidas anteriormente
    append([PrimSem], [SegSemNaoRepetido], Semestres).

% Predicado auxiliar que e verdade se todas as disciplinas de ListaDisciplinas existirem no curso Curso.
disciplinasCurso([], _).
disciplinasCurso([Disciplina|RestantesDisciplinas], Curso) :-
    % Verifica cada uma das disciplinas da lista separadamente
    evento(ID, Disciplina, _, _, _), turno(ID, Curso, _, _), !,
    disciplinasCurso(RestantesDisciplinas, Curso).

% Predicado auxiliar que e verdade se PrimSem e a lista de disciplinas presentes em ListaDisciplinas
% que ocorrem no primeiro semestre.
organizaDisciplinasPrimSem([], _,[]).
% Caso a disciplina ocorra no primeiro semestre
organizaDisciplinasPrimSem([Disciplina|RestantesDisciplinas], Curso, ListaDisciplinasPrimSem) :-
    evento(ID, Disciplina, _, _, _), horario(ID, _, _, _, _, Periodo),
    member(Periodo, [p1, p2, p1_2]), !,
    organizaDisciplinasPrimSem(RestantesDisciplinas, Curso, RestantesDisciplinasPrimSem),
    sort([Disciplina|RestantesDisciplinasPrimSem], ListaDisciplinasPrimSem).
% Caso a disciplina ocorra no segundo semestre
organizaDisciplinasPrimSem([_|RestantesDisciplinas], Curso, ListaDisciplinasPrimSem) :-
    organizaDisciplinasPrimSem(RestantesDisciplinas, Curso, ListaDisciplinasPrimSem).

% Predicado auxiliar que e verdade se SegSem e a lista de disciplinas presentes em ListaDisciplinas
% que ocorrem no segundo semestre.
organizaDisciplinasSegSem([], _,[]).
% Caso a disciplina ocorra no segundo semestre
organizaDisciplinasSegSem([Disciplina|RestantesDisciplinas], Curso, ListaDisciplinasSegSem) :-
    evento(ID, Disciplina, _, _, _), horario(ID, _, _, _, _, Periodo),
    member(Periodo, [p3, p4, p3_4]), !,
    organizaDisciplinasSegSem(RestantesDisciplinas, Curso, RestantesDisciplinasSegSem),
    sort([Disciplina|RestantesDisciplinasSegSem], ListaDisciplinasSegSem).
% Caso a disciplina ocorra no primeiro semestre
organizaDisciplinasSegSem([_|RestantesDisciplinas], Curso, ListaDisciplinasSegSem) :-
    organizaDisciplinasSegSem(RestantesDisciplinas, Curso, ListaDisciplinasSegSem).


/*
horasCurso(Periodo, Curso, Ano, TotalHoras) e verdade se TotalHoras for o numero
de horas total dos eventos associadas ao curso Curso, no ano Ano e periodo Periodo.
O predicado contabiliza tambem o numero de horas das disciplinas semestrais do curso,
ou seja, as que ocorrem em p1_2 e p3_4.
*/
horasCurso(Periodo, Curso, Ano, TotalHoras) :-
    eventosCursoPeriodo(Periodo, Curso, Ano, ListaEventos),
    horasListaEventos(ListaEventos, TotalHoras).

% Predicado auxiliar que encontra os todos os eventos do curso Curso que ocorrem no periodo Periodo.
eventosCursoPeriodo(Periodo, Curso, Ano, ListaEventos) :-
    periodo_aux(Periodo, Semestre), !,
    % Procura eventos do curso Curso no periodo Periodo e no respetivo semestre
    findall(ID, (turno(ID, Curso, Ano, _), horario(ID, _, _, _, _, Periodo)), EventosPeriodo),
    findall(ID, (turno(ID, Curso, Ano, _), horario(ID, _, _, _, _, Semestre)), EventosSemestre),
    % Junta as duas listas obtidas numa so e ordena-a
    append(EventosPeriodo, EventosSemestre, Eventos),
    sort(Eventos, ListaEventos).

% Predicado auxiliar que calcula o numero total de horas dos eventos de ListaEventos.
horasListaEventos([], 0).
horasListaEventos([Evento|RestantesEventos], Horas) :-
    % Verifica, um a um, cada evento da lista
    horario(Evento, _, _, _, Duracao, _),
    horasListaEventos(RestantesEventos, HorasAtual),
    Horas is HorasAtual + Duracao.


/*
evolucaoHorasCurso(Curso, Evolucao) e verdade se Evolucao for uma lista de tuplos
na forma (Ano, Periodo, NumHoras), ordenada por ano (crescente) e periodo em que
NumHoras e o total de horas associadas ao curso Curso, no ano Ano e periodo Periodo.
*/
evolucaoHorasCurso(Curso, Evolucao) :-
    % Procura toda a informacao nas condicoes referidas e adiciona-a a uma lista
    findall((Ano, Periodo, NumHoras), (member(Ano, [1,2,3]),
    member(Periodo, [p1, p2, p3, p4]), horasCurso(Periodo, Curso, Ano, NumHoras)), 
    ListaTuplos),
    % Ordena a lista
    sort(ListaTuplos, Evolucao).


/*
ocupaSlot(HoraInicioDada, HoraFimDada, HoraInicioEvento, HoraFimEvento, Horas) e
verdade se Horas for o numero de horas sobrepostas entre o evento que tem inicio
em HoraInicioEvento e fim em HoraFimEvento, e o slot que tem inicio em HoraInicioDada
e fim em HoraFimDada. Se nao existirem sobreposicoes, o predicado falha (false).
*/
ocupaSlot(HoraInicioDada, HoraFimDada, HoraInicioEvento, HoraFimEvento, Horas) :-
    % Verifica se ha sobreposicao entre o intervalo de tempo dado e o evento
    HoraInicioDada =< HoraFimEvento, HoraFimDada >= HoraInicioEvento,
    % O numero de horas sobrepostas sera a diferenca entre a hora de fim minima e a hora de inicio maxima
    HoraMin is max(HoraInicioDada, HoraInicioEvento), HoraMax is min(HoraFimDada, HoraFimEvento),
    Horas is HoraMax - HoraMin.


/*
numHorasOcupadas(Periodo, TipoSala, DiaSemana, HoraInicio, HoraFim, SomaHoras) e
verdade se SomaHoras for o numero de horas ocupadas nas salas do tipo TipoSala,
no intervalo de tempo definido entre HoraInicio e HoraFim, no dia da semana DiaSemana,
e no periodo Periodo. O predicado contabiliza tambem a informacao correspondente a
disciplinas semestrais, ou seja, p1_2 e p3_4.
*/
numHorasOcupadas(Periodo, TipoSala, DiaSemana, HoraInicio, HoraFim, SomaHoras) :-
    % Obtem a lista de salas do tipo TipoSala e verifica cada uma delas
    salas(TipoSala, ListaSalas),
    numHorasOcupadasAux(Periodo, ListaSalas, DiaSemana, HoraInicio, HoraFim, SomaHoras).

% Predicado auxiliar que verifica as salas de ListaSalas, uma a uma, de forma a calcular
% o numero de horas ocupadas em cada uma delas no dia e na hora especificados.
numHorasOcupadasAux(_, [], _, _, _, 0).
numHorasOcupadasAux(Periodo, [Sala|RestantesSalas], DiaSemana, HoraInicio, HoraFim, SomaHoras) :-
    % Utiliza um predicado auxiliar para calcular o numero de horas ocupadas de cada sala e soma as das restantes
    numHorasOcupadasSala(Periodo, Sala, DiaSemana, HoraInicio, HoraFim, SomaHorasSala),
    numHorasOcupadasAux(Periodo, RestantesSalas, DiaSemana, HoraInicio, HoraFim, SomaHorasRestantesSalas), !,
    SomaHoras is SomaHorasSala + SomaHorasRestantesSalas.

% Predicado auxiliar que calcula o numero de horas ocupadas numa sala no dia e na hora especificados.
numHorasOcupadasSala(Periodo, Sala, DiaSemana, HoraInicio, HoraFim, SomaHorasSala) :-
    % Verifica se Periodo e p1, p2, p3 ou p4 e, nesse caso, encontra o semestre correspondente
    periodo_aux(Periodo, Semestre), !,
    % Procura todos os eventos nas condicoes referidas e adiciona as respetivas duracoes a duas listas
    findall(Duracao, (evento(ID, _, _, _, Sala), horario(ID, DiaSemana, InicioAula, FimAula, _, Periodo),
    ocupaSlot(HoraInicio, HoraFim, InicioAula, FimAula, Duracao)), ListaDuracoesSalaPeriodo),
    findall(Duracao, (evento(ID, _, _, _, Sala), horario(ID, DiaSemana, InicioAula, FimAula, _, Semestre),
    ocupaSlot(HoraInicio, HoraFim, InicioAula, FimAula, Duracao)), ListaDuracoesSalaSemestre),
    % Junta as duas listas (periodo e semestre) numa so e soma todos os elementos da lista resultante
    append(ListaDuracoesSalaPeriodo, ListaDuracoesSalaSemestre, ListaDuracoesSala),
    sum_list(ListaDuracoesSala, SomaHorasSala).
% Caso Periodo seja um semetre, isto e, p1_2 ou p3_4
numHorasOcupadasSala(Periodo, Sala, DiaSemana, HoraInicio, HoraFim, SomaHorasSala) :-
    findall(Duracao, (evento(ID, _, _, _, Sala), horario(ID, DiaSemana, InicioAula, FimAula, _, Periodo),
    ocupaSlot(HoraInicio, HoraFim, InicioAula, FimAula, Duracao)), ListaDuracoesSala),
    sum_list(ListaDuracoesSala, SomaHorasSala).


/*
ocupacaoMax(TipoSala, HoraInicio, HoraFim, Max) e verdade se Max for o numero de
horas possiveis de ser ocupadas por salas do tipo TipoSala (ver acima), no intervalo
de tempo definido entre HoraInicio e HoraFim. Em termos praticos, assume-se que Max
e o intervalo de tempo dado (HoraFim - HoraInicio), multiplicado pelo numero de salas
em jogo do tipo TipoSala.
*/
ocupacaoMax(TipoSala, HoraInicio, HoraFim, Max) :-
    salas(TipoSala, ListaSalas), length(ListaSalas, NumSalas),
    Max is NumSalas * (HoraFim - HoraInicio).


/*
percentagem(SomaHoras, Max, Percentagem) e verdade se Percentagem for a divisao
de SomaHoras por Max, multiplicada por 100.
*/
percentagem(SomaHoras, Max, Percentagem) :-
    Percentagem is (SomaHoras/Max) * 100.


/*
ocupacaoCritica(HoraInicio, HoraFim, Threshold, Resultados) e verdade se Resultados
for uma lista ordenada de tuplos do tipo casosCriticos(DiaSemana, TipoSala, Percentagem)
em que DiaSemana, TipoSala e Percentagem sao, respetivamente, um dia da semana, um tipo
de sala e a sua percentagem de ocupacao, no intervalo de tempo entre HoraInicio e HoraFim,
e supondo que a percentagem de ocupacao relativa a esses elementos esta acima de um dado
valor critico (Threshold).
*/
ocupacaoCritica(HoraInicio, HoraFim, Threshold, Resultados) :-
    % Cria uma lista com todos os tipos de sala existentes
    findall(TipoSala, salas(TipoSala, _), ListaTiposSala),
    % Procura todos os casos criticos consoante as condicoes referidas e adiciona-os a uma lista
    findall(casosCriticos(DiaSemana, TipoSala, Percentagem),
    (member(TipoSala, ListaTiposSala),
    member(DiaSemana, [segunda-feira, terca-feira, quarta-feira, quinta-feira, sexta-feira]),
    member(Periodo, [p1, p2, p3, p4]),
    numHorasOcupadas(Periodo, TipoSala, DiaSemana, HoraInicio, HoraFim, SomaHoras),
    ocupacaoMax(TipoSala, HoraInicio, HoraFim, Max),
    % Calcula a percentagem de ocupacao do tipo de sala e compara-a com o valor critico
    percentagem(SomaHoras, Max, Percentagem_NaoArredondada),
    Percentagem_NaoArredondada > Threshold,
    % Arredonda a percentagem, sendo este valor adicionado ao tuplo de cada caso critico
    ceiling(Percentagem_NaoArredondada, Percentagem)), ResultadosNaoOrd),
    % Ordena da lista de resultados
    sort(ResultadosNaoOrd, Resultados).


/*
ocupacaoMesa(ListaPessoas, ListaRestricoes, OcupacaoMesa) e verdade se ListaPessoas
for a lista com o nome das pessoas a sentar a mesa, ListaRestricoes for a lista de
restricoes a verificar e OcupacaoMesa for uma lista com tres listas, em que a primeira
contem as pessoas de um lado da mesa (X1, X2 e X3), a segunda as pessoas a cabeceira
(X4 e X5) e a terceira as pessoas do outro lado da mesa (X6, X7 e X8), de modo a
que essas pessoas sao exactamente as da ListaPessoas e verificam todas as restricoes 
de ListaRestricoes.
*/
ocupacaoMesa(ListaPessoas, ListaRestricoes, OcupacaoMesa) :-
    % Define a disposicao da mesa e realiza todas as permutacoes possiveis da mesma
    OcupacaoMesa = [[X1, X2, X3], [X4, X5], [X6, X7, X8]],
    permutation(ListaPessoas, [X1, X2, X3, X4, X5, X6, X7, X8]),
    % Percorre a lista de restricoes e verifica qual a permutacao que verifica todas elas
    analisaRestricoes(ListaRestricoes, OcupacaoMesa).

% Predicado auxiliar que percorre ListaRestricoes de forma a verificar cada uma das restricoes.
analisaRestricoes([], _).
analisaRestricoes([Restricao|RestantesRestricoes], OcupacaoMesa) :-
    % Analisa todas as restricoes, uma de cada vez, recorrendo a outro predicado auxiliar
    confirmaRestricao(Restricao, OcupacaoMesa),
    analisaRestricoes(RestantesRestricoes, OcupacaoMesa).

% Predicado auxiliar que verifica se OcupacaoMesa respeita cada uma das restricoes impostas.
confirmaRestricao(_, []).

% cab1(NomePessoa) e verdade se NomePessoa for a pessoa que fica na cabeceira 1 - X4.
confirmaRestricao(cab1(NomePessoa), [_, [NomePessoa, _], _]).

% cab2(NomePessoa) e verdade se NomePessoa for a pessoa que fica na cabeceira 2 - X5.
confirmaRestricao(cab2(NomePessoa), [_, [_, NomePessoa], _]).

% honra(NomePessoa1, NomePessoa2) e verdade se NomePessoa1 estiver numa das cabeceiras
% e NomePessoa2 ficar a sua direita.
confirmaRestricao(honra(NomePessoa1, NomePessoa2), [_, [NomePessoa1, _], [NomePessoa2, _, _]]).
confirmaRestricao(honra(NomePessoa1, NomePessoa2), [[_, _, NomePessoa2], [_, NomePessoa1], _]).

% lado(NomePessoa1, NomePessoa2) e verdade se NomePessoa1 e NomePessoa2 ficarem lado a lado na mesa.
confirmaRestricao(lado(NomePessoa1, NomePessoa2), [[NomePessoa1, NomePessoa2, _], _, _]).
confirmaRestricao(lado(NomePessoa1, NomePessoa2), [[_, NomePessoa1, NomePessoa2], _, _]).
confirmaRestricao(lado(NomePessoa1, NomePessoa2), [_, _, [NomePessoa1, NomePessoa2, _]]).
confirmaRestricao(lado(NomePessoa1, NomePessoa2), [_, _, [_, NomePessoa1, NomePessoa2]]).
confirmaRestricao(lado(NomePessoa1, NomePessoa2), [[NomePessoa2, NomePessoa1, _], _, _]).
confirmaRestricao(lado(NomePessoa1, NomePessoa2), [[_, NomePessoa2, NomePessoa1], _, _]).
confirmaRestricao(lado(NomePessoa1, NomePessoa2), [_, _, [NomePessoa2, NomePessoa1, _]]).
confirmaRestricao(lado(NomePessoa1, NomePessoa2), [_, _, [_, NomePessoa2, NomePessoa1]]).

% naoLado(NomePessoa1, NomePessoa2) e verdade se NomePessoa1 e NomePessoa2 nao ficarem lado a lado na mesa.
confirmaRestricao(naoLado(NomePessoa1, NomePessoa2), OcupacaoMesa) :-
    \+ confirmaRestricao(lado(NomePessoa1, NomePessoa2), OcupacaoMesa).

% frente(NomePessoa1, NomePessoa2) e verdade se NomePessoa1 e NomePessoa2 ficarem
% exatamente frente a frente na mesa.
confirmaRestricao(frente(NomePessoa1, NomePessoa2), [[NomePessoa1, _, _], _, [NomePessoa2, _, _]]).
confirmaRestricao(frente(NomePessoa1, NomePessoa2), [[_, NomePessoa1, _], _, [_, NomePessoa2, _]]).
confirmaRestricao(frente(NomePessoa1, NomePessoa2), [[_, _, NomePessoa1], _, [_, _, NomePessoa2]]).
confirmaRestricao(frente(NomePessoa1, NomePessoa2), [[NomePessoa2, _, _], _, [NomePessoa1, _, _]]).
confirmaRestricao(frente(NomePessoa1, NomePessoa2), [[_, NomePessoa2, _], _, [_, NomePessoa1, _]]).
confirmaRestricao(frente(NomePessoa1, NomePessoa2), [[_, _, NomePessoa2], _, [_, _, NomePessoa1]]).

% naoFrente(NomePessoa1, NomePessoa2) e verdade se NomePessoa1 e NomePessoa2
% nao ficarem frente a frente na mesa.
confirmaRestricao(naoFrente(NomePessoa1, NomePessoa2), OcupacaoMesa) :-
    \+ confirmaRestricao(frente(NomePessoa1, NomePessoa2), OcupacaoMesa).