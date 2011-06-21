goTo("agent1",2,6).
goTo("agent2",2,7).

!start.

+!start: true <-
	?getMap(MAP_ID);
	.my_name(MyName);
	register(MyName) [artifact_id(MAP_ID)];
	focus(MAP_ID);
	.wait(500);
	!work.
	
/* Find the MAP_ID */
+?getMap(MAP_ID): true <-
	lookupArtifact("map", MAP_ID).

-?getMap(MAP_ID): true <-
	.wait(10);
	?getMap(MAP_ID).

+push_norm(NormID, Activation, Expiration, Content, Source) : true <-
	.add_plan(Activation, Source);
	if (Expiration \== "") {
		.add_plan(Expiration,Source);
	}
	.add_plan(Content, Source);
	.println("added norm ",NormID).	
	
+!work: true <-
	.my_name(MyNameTerm);
	.term2string(MyNameTerm,MyName);
	?goTo(MyName,X,Y);
	planPath(MyName,X,Y);
	!check_all_norms.
	
+!check_all_norms : true <-
	?norm_id_list(L);
	for (.member(NormID,L)) {
		!check_norm(NormID);
	}
	.println("checked all").	
		
+!check_norm(NormID) : true <-
	.println("check norm ",NormID);
	!norm_activation(NormID,Conflicts);
	!norm_content(NormID,Conflicts).
	
-!check_norm(NormID) : true <-
	true.
	