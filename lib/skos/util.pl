:- module(skos_util, [
	      skos_is_vocabulary/1,
	      skos_notation_ish/2,
	      skos_all_labels/2,
	      skos_related_concepts/2,
	      skos_parent_child/2,
	      skos_descendant_of/2,
	      skos_descendant_of/4
	  ]).

:- use_module(library('semweb/rdf_db')).
:- use_module(library('semweb/rdfs')).
:- use_module(library('semweb/rdf_label')).

:- multifile
	skos_is_vocabulary/1.

:- rdf_meta
	skos_is_vocabulary(r),
	skos_notation_ish(r, -),
	skos_all_labels(r, -),
	skos_related_concepts(r,-),
	skos_parent_child(r,r),
	skos_descendant_of(r,r).

%%	skos_is_vocabulary(+Voc) is semidet.
%%	skos_is_vocabulary(-Voc) is nondet.
skos_is_vocabulary(Voc) :-
	rdfs_individual_of(Voc, skos:'ConceptScheme').

%%	notation_ish(+Concept, -NotationIsh) is det.
%
%	Unify NotationIsh with a label extend by (notation).
%	For notation, use the skos:notation or dc/dcterms:identifier
skos_notation_ish(Concept, NotationIsh) :-
	rdf_display_label(Concept, Label),
	(   (rdf(Concept, skos:notation, N)
	    ;	rdf_has(Concept, skos:notation, N)
	    ;	rdf_has(Concept, dc:identifier, N)
	    )
	->  literal_text(N, LT),
	    format(atom(NotationIsh), '~w (~w)', [Label, LT])
	;   NotationIsh = Label
	).


%%	skos_all_labels(URI, Labels) is det.
%
%	Find all labels using rdf_label/2.
%	Note that rdf_label itself is skos hooked...
skos_all_labels(R,Labels) :-
	findall(AltLabel, (rdf_label(R,Lit),
			   literal_text(Lit, AltLabel)
			  ),
		Labels0),
	sort(Labels0,Labels).


%%	skos_related_concepts(?Resource, ?Concepts) is det.
%
%	Related Concepts are linked by skos:related to Resource.

skos_related_concepts(S, Rs) :-
	findall(R, skos_related(S, R), Rs0),
	sort(Rs0, Rs).

skos_related(R1, R2) :-
	rdf_has(R1, skos:related, R2).
skos_related(R2, R1) :-
	rdf_has(R2, skos:related, R1).

%%	skos_parent_child(?Parent, ?Child) is nondet.
%
%	Evaluates to true if Parent is a broader concept of Child,
%	Child a narrower concept of Parent and Parent != Child.

skos_parent_child(Parent, Child) :-
	(   rdf_has(Child, skos:broader, Parent)
	;   rdf_has(Parent, skos:narrower, Child)
	),
	Parent \= Child.

%%	skos_descendant_of(+Concept, -Descendant) is semidet.
%
%	Descendent is a direct or indirect descendant of Concept.

skos_descendant_of(Concept, D) :-
	rdf_reachable(D, skos:broader, Concept),
	\+ D = Concept.
skos_descendant_of(Concept, D) :-
	rdf_reachable(Concept, skos:narrower, D),
	\+ D = Concept,
	\+ rdf_reachable(D, skos:broader, Concept).

%%	skos_descendant_of(+Concept, Descendent, MaxSteps, Steps) is
%	semidet.
%
%	Descendent is a direct or indirect descendent of Concept in
%	Steps steps.

skos_descendant_of(Concept, D, MaxSteps, Steps) :-
	rdf_reachable(D, skos:broader, Concept, MaxSteps, Steps),
	\+ D = Concept.
skos_descendant_of(Concept, D, MaxSteps, Steps) :-
	rdf_reachable(Concept, skos:narrower, D, MaxSteps, Steps),
	\+ D = Concept,
	\+ rdf_reachable(D, skos:broader, Concept, MaxSteps, Steps).