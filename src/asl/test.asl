//norm(0, step(N) & N > 0 & my_name(MyName) & loaded_packet(_,Type,_,_) & (Type == 1 | Type == 2), false, my_name(MyName) & truck(MyName,3,_,_)).
//norm(1, step(N) & N > 0 & my_name(MyName) & loaded_packet(_,Type,_,_) & Type \== 1 & Type \== 2, false, my_name(MyName) & not truck(MyName,3,_,_)).
//norm(2, step(N) & N > 0 & my_name(MyName) & loaded_packet(_,Type,_,_) & (Type == 3 | Type == 5), false, my_name(MyName) & truck(MyName,2,_,_)).
//norm(3, step(N) & N > 0 & my_name(MyName) & loaded_packet(_,Type,_,_) & Type \== 3 & Type \== 5, false, my_name(MyName) & not truck(MyName,2,_,_)).

norm(4, replanning & pos(Ag,X,Y,T), false, not pos(X,Y,T)).
norm(5, my_name(MyName) & pos(MyName,X,Y,T) & pos(Name,X,Y,T) & Name \== MyName, 
		false,
		.findall(1,pos(MyName,_,_,_),P1) & .findall(2,pos(Name,_,_,_),P2) & 
		.length(P1,N1) & .length(P2,N2) & (N1 < N2 | (N1==N2 & MyName < Name))).

!init.


+!init: true <-
	?get_map(MapID);
	.my_name(MyNameTerm);
	.term2string(MyNameTerm,MyName);
	+my_name(MyName);
	+packet_selection;
	+step(0);
	focus(MapID);
	register(MyNameTerm) [artifact_id(MapID)].

+?get_map(MapID): true <-
	lookupArtifact("map", MapID).

-?get_map(MapID): true <-
	.wait(10);
	?get_map(MapID).


/* PLANNING */
+tick(N) : N >= 1 & packet_selection <-
	-+step(N);
	.println("Tick ",N," [SELECTING PACKET]");
	?my_name(MyName);
	?current_pos(MyName,SX,SY);
	?step(N);
	sync_start(MyName);
	.findall(packet(math.abs(SX-PX)+math.abs(SY-PY),Type,PX,PY),packet(Type,PX,PY),Packets);
	if(Packets \== [])
	{
		.findall(norm(ID,A,E,C),norm(ID,A,E,C),Norms);
		+norms_infringed([]);
		for (.member(packet(D,T,X,Y),Packets)) {
			+packet(MyName,T,X,Y);
			for (.member(norm(ID,A,E,C),Norms)) {
					if (A & not E & not C) {
						+bad_packet;
						?norms_infringed(NormList);
						.concat(NormList,[ID],InfNormList);
						-+norms_infringed(InfNormList);
					}
			}
			if (not bad_packet) {
				+selected_packet(packet(D,T,X,Y));
			}
			else {
				-bad_packet;
			}
			-packet(MyName,T,X,Y);
		}
		.findall(packet(D,T,X,Y),selected_packet(packet(D,T,X,Y)),L);
		if (L \== []) {
			.min(L,packet(D,T,X,Y));
			for (.member(P,L)) {
				-selected_packet(P);
			}
			.println("Selected packet: ",T," ",X," ",Y);
			-norms_infringed(_);
			
			?valid_neighbours(pos(X,Y,0),Neighbours);
			if (Neighbours \== []) {
				.member(pos(NX,NY,NT),Neighbours);
				?find_path(pos(NX,NY),Path);
				if (Path == []) {
					.println("No path found to ",pos(NX,NY));
					stay(MyName,SX,SY);
					sync_end(MyName);
				}
				else {
					register_packet(MyName,T,X,Y);
					-packet_selection;
					+moving;
					publish_path(MyName,Path);
					planned(MyName,SX,SY,N);
					sync_end(MyName);
				}
			}
			else {
				.println("No valid neighbours found for selected packet");
				stay(MyName,SX,SY);
				sync_end(MyName);
			}
		}
		else {
			.println("No packet selected due to norms");
			?norms_infringed(NormList);
			.println("Infringed norms: ",NormList);
			stay(MyName,SX,SY);
			sync_end(MyName);
		}
	}
	else {
		.println("No packets remaining, returning to depot");
		-packet_selection;
		+select_depot;
		stay(MyName,SX,SY);
		sync_end(MyName);
	}.

+tick(N) : N > 1 & moving <-
	-+step(N);
	.println("Tick ",N," [MOVING]");
	?my_name(MyName);
	?current_pos(MyName,CX,CY);
	!check_norms(NormsOK);
	if (not NormsOK) {
		.println("Norm checking failed while moving! Selecting a different packet!");
		-moving;
		+packet_selection;
		.findall(pos(PX,PY,PT),pos(MyName,PX,PY,PT),PathToRemove);
		unpublish_path(MyName,PathToRemove,CX,CY,N);
		?packet(MyName,T,X,Y);
		unregister_packet(MyName,T,X,Y);
		stay(MyName,CX,CY);
	} 
	else {
		.findall(pos(MyName,X,Y,T),pos(MyName,X,Y,T),L);
		.length(L,Len);
		?pos(MyName,X,Y,N);
		if (Len > 4) {
			.findall(current_pos(Name,CPOSX,CPOSY),current_pos(Name,CPOSX,CPOSY),Cposes);
			move(MyName,CX,CY,X,Y,N);
		}
		else {
			-moving;
			+loading;
			move(MyName,CX,CY,X,Y,N);
		}
	}.

+tick(N) : N > 1 & loading <-
	-+step(N);
	.println("Tick ",N," [LOADING]");
	?my_name(MyName);
	?current_pos(MyName,CX,CY);
	!check_norms(NormsOK);
	if(not NormsOK) {
		.println("Norm checking failed while loading! Selecting a different packet!");
		-loading;
		+packet_selection;
		?packet(MyName,T,X,Y);
		unregister_packet(MyName,T,X,Y);
		stay(MyName,CX,CY);
	}
	else {
		-loading;
		+truck_selection;
		?packet(MyName,T,PX,PY);
		load(MyName,CX,CY,N,T,PX,PY);
	}.

+tick(N) : N > 1 & truck_selection <-
	-+step(N);
	.println("Tick ",N," [SELECTING TRUCK]");
	?my_name(MyName);
	?current_pos(MyName,SX,SY);
	sync_start(MyName);
	.findall(truck(math.abs(SX-PX)+math.abs(SY-PY),Type,PX,PY),truck(Type,PX,PY),Trucks);
	if(Trucks \== []) {
		.findall(norm(ID,A,E,C),norm(ID,A,E,C),Norms);
		+norms_infringed([]);
		for (.member(truck(D,T,X,Y),Trucks)) {
			+truck(MyName,T,X,Y);
			for (.member(norm(ID,A,E,C),Norms)) {
					if (A & not E & not C) {
						+bad_truck;
						?norms_infringed(NormList);
						.concat(NormList,[ID],InfNormList);
						-+norms_infringed(InfNormList);
					}
			}
			if (not bad_truck) {
				+selected_truck(truck(D,T,X,Y));
			}
			else {
				-bad_truck;
			}
			-truck(MyName,T,X,Y);
		}
		.findall(truck(D,T,X,Y),selected_truck(truck(D,T,X,Y)),L);
		if (L \== []) {
			.min(L,truck(D,T,X,Y));
			for (.member(P,L)) {
				-selected_truck(P);
			}
			.println("Selected truck: ",T," ",X," ",Y);
			-norms_infringed(_);
			
			?valid_neighbours(pos(X,Y,0),Neighbours);
			if (Neighbours \== []) {
				.member(pos(NX,NY,NT),Neighbours);
				?find_path(pos(NX,NY),Path);
				if (Path == []) {
					.println("No path found to ",pos(NX,NY));
					stay(MyName,SX,SY);
					sync_end(MyName);
				}
				else {
					register_truck(MyName,T,X,Y);
					-truck_selection;
					+carrying;
					publish_path(MyName,Path);
					planned(MyName,SX,SY,N);
					sync_end(MyName);
				}
			}
		}
		else {
			.println("No truck selected due to norms");
			?norms_infringed(NormList);
			.println("Infringed norms: ",NormList);
			stay(MyName,SX,SY);
			sync_end(MyName);
		}
	}
	else {
		.println("!!! No trucks remaining !!!");
		sync_end(MyName);
	}.

+tick(N) : N > 1 & carrying <-
	-+step(N);
	.println("Tick ",N," [CARRYING]");
	?my_name(MyName);
	?current_pos(MyName,CX,CY);
	!check_norms(NormsOK);
	if (not NormsOK) {
		.println("Norm checking failed while! Selecting a different truck!");
		-carrying;
		+truck_selection;
		.findall(pos(PX,PY,PT),pos(MyName,PX,PY,PT),PathToRemove);
		unpublish_path(MyName,PathToRemove,CX,CY,N);
		?truck(MyName,T,X,Y);
		unregister_truck(MyName,T,X,Y);
		stay(MyName,CX,CY);
	} 
	else {
		.findall(pos(MyName,X,Y,T),pos(MyName,X,Y,T),L);
		.length(L,Len);
		?pos(MyName,X,Y,N);
		if (Len > 4) {
			carry(MyName,CX,CY,X,Y,N);
		}
		else {
			-carrying;
			+unloading;
			carry(MyName,CX,CY,X,Y,N);
		}
	}.

+tick(N) : N > 1 & unloading <-
	-+step(N);
	.println("Tick ",N," [UNLOADING]");
	?my_name(MyName);
	?current_pos(MyName,CX,CY);
	!check_norms(NormsOK);
	if(not NormsOK) {
		.println("Norm checking failed while unloading! Selecting a different truck!");
		-unloading;
		+packet_selection;
		?truck(MyName,T,X,Y);
		unregister_truck(MyName,T,X,Y);
		stay(MyName,CX,CY);
	}
	else {
		-unloading;
		+packet_selection;
		?loaded_packet(MyName,LPT,LPX,LPY);
		?truck(MyName,TT,TX,TY);
		unload(MyName,CX,CY,N,LPT,LPX,LPY,TT,TX,TY);
	}.

+tick(N) : N > 1 & select_depot <-
	-+step(N);
	.println("Tick ",N," [RETURN TO DEPOT]");
	?my_name(MyName);
	?current_pos(MyName,SX,SY);
	?step(N);
	sync_start(MyName);
	?depot(DX,DY);
	?find_path(pos(DX,DY),Path);
	if (Path == []) {
		.println("No path found to ",pos(DX,DY));
		stay(MyName,SX,SY);
		//unregister_depot(MyName,DX,DY);
		sync_end(MyName);
	}
	else {
		register_depot(MyName,DX,DY);
		-select_depot;
		+move_to_depot;
		publish_path(MyName,Path);
		planned(MyName,SX,SY,N);
		sync_end(MyName);
	}.

+tick(N) : N > 1 & move_to_depot <-
	-+step(N);
	.println("Tick ",N," [MOVING TO DEPOT]");
	?my_name(MyName);
	?current_pos(MyName,CX,CY);
	.findall(pos(MyName,X,Y,T),pos(MyName,X,Y,T),L);
	.length(L,Len);
	?pos(MyName,X,Y,N);
	if (Len > 3) {
	.findall(current_pos(Name,CPOSX,CPOSY),current_pos(Name,CPOSX,CPOSY),Cposes);
	move(MyName,CX,CY,X,Y,N);
	}
	else {
		-move_to_depot;
		+idle;
		.println("BACK HOMEEEEEE !!!");
		//move(MyName,CX,CY,X,Y,N);
	}.



/* PATHFINDING */
+?valid_neighbours(pos(X,Y,T),Res): true <-
	.findall(norm(ID,A,E,C),norm(ID,A,E,C),Norms);
	?neighbours(pos(X,Y),Neighbours);
	for (.member(pos(PX,PY),Neighbours)) {
		+pos(PX,PY,T);
		for (.member(norm(ID,A,E,C),Norms)) {
			if (A & not E & not C) {
				+bad_neighbour(pos(PX,PY,T));
			}
		}
		if (not bad_neighbour(pos(PX,PY,T))) {
			+valid_neighbour(pos(PX,PY,T));
		}
		else {
			-bad_neighbour(pos(PX,PY,T));
		}
		-pos(PX,PY,T);
	}
	.findall(P,valid_neighbour(P),Res);
	.findall(valid_neighbour(P),valid_neighbour(P),L);
	for (.member(VN,L)) {-VN;}.

+?neighbours(pos(X,Y),Res): true <-
	+neighbours_list([]);
	?neighbours_list(L1);
	if (map(X-1,Y,V) & V==0) {
		.concat(L1,[pos(X-1,Y)],LL1);
		-+neighbours_list(LL1);
	}
	?neighbours_list(L2);
	if (map(X+1,Y,V) & V==0) {
		.concat(L2,[pos(X+1,Y)],LL2);
		-+neighbours_list(LL2);
	}
	?neighbours_list(L3);
	if (map(X,Y-1,V) & V==0) {
		.concat(L3,[pos(X,Y-1)],LL3);
		-+neighbours_list(LL3);
	}
	?neighbours_list(L4);
	if (map(X,Y+1,V) & V==0) {
		.concat(L4,[pos(X,Y+1)],LL4);
		-+neighbours_list(LL4);
	}
	?neighbours_list(L5);
	-neighbours_list(L5);
	Res = L5.

+?find_path(Dest,Path): true <-
	?step(Step);
	?my_name(MyName);
	?current_pos(Name,SX,SY);
	+queue(0,SX,SY,Step);
	+visited(SX,SY);
	while (.findall(queue(I,X,Y,T),queue(I,X,Y,T),Queue) & .length(Queue,Len) & Len>0) {
		.min(Queue,queue(I1,CX,CY,CT));
		-queue(I1,CX,CY,CT);
		?valid_neighbours(pos(CX,CY,CT+1),Neighbours);
		for (.member(pos(NX,NY,NT),Neighbours)) {
			if (not visited(NX,NY)) {
				.findall(queue(I,X,Y,T),queue(I,X,Y,T),Queue2);
				if (Queue2 == []) {
					I2 = 1;
				}
				else {
					.max(Queue,queue(I2,_,_,_));
				}
				+queue(I2+1,NX,NY,NT);
				+visited(NX,NY);
				+parent(pos(NX,NY,NT),pos(CX,CY,CT));
				if (pos(NX,NY)==Dest) {
					+path(pos(NX,NY,NT+2));
					+path(pos(NX,NY,NT+1));
					P = pos(NX,NY,NT);
					+current(P);
					while (current(Pos) & Pos \== pos(SX,SY,Step)) {
						+path(Pos);
						?parent(Pos,Parent);
						-+current(Parent);
					}
				}
			}
		}
	}
	.findall(pos(X,Y,T),path(pos(X,Y,T)),FirstPath);
	.findall(queue(I,X,Y,T),queue(I,X,Y,T),L1);
	for (.member(Q,L1)) {-Q;}
	.findall(visited(X,Y),visited(X,Y),L2);
	for (.member(V,L2)) {-V;}
	.findall(parent(X,Y),parent(X,Y),L3);
	for (.member(P,L3)) {-P;}
	.findall(path(X),path(X),L4);
	for (.member(P,L4)) {-P;}
	-current(_);
	for (.member(pos(FX,FY,FT),FirstPath)) {
		+pos(MyName,FX,FY,FT);
	}
	!check_norms(NormsOK);
	for (.member(pos(FX,FY,FT),FirstPath)) {
		-pos(MyName,FX,FY,FT);
	}
	if (not NormsOK & not replanning) {
		+replanning;
		?find_path(Dest,AlternativePath);
		Path = AlternativePath;
	}
	else {
		-replaning;
		Path = FirstPath;
	}.


/* NORM CHECKING */
+!check_norms(Res): true <-
	.findall(norm(ID,A,E,C),norm(ID,A,E,C),Norms);
	+norms_infringed([]);
	for (.member(norm(ID,A,E,C),Norms)) {
		if (A & not E & not C) {
			+conflicting_norm;
			?norms_infringed(NormList);
			.concat(NormList,[ID],InfNormList);
			-+norms_infringed(InfNormList);
		}
	}
	if (conflicting_norm) {
		-conflicting_norm;
		Res = false;
	}
	else {
		Res = true;
		-norms_infringed(_);
	}.