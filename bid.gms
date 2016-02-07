$eolcom #
# The model for the paper "Strategic offering of a flexible producer to sequential day-ahead and intraday markets"
# A three-node example
# Tuomas Rintamäki 2016
# tuomas.rintamaki@aalto.fi


*------------------------------------------------------------------------------*
* Set definitions
*------------------------------------------------------------------------------*

Set
    n               nodes                           / n1*n3 /
    u               generation types                / u1*u3 /
    b               bid block                       / b1*b2 /
    l               transmission lines              / l1*l3 /
    i               discrete da generation levels   / i1*i6 /
    j               discrete up-regulation levels   / j1*j6 /
    k               discrete down-regulation levels / k1*k6 /
    s               scenarios                       / s1*s4 /
;

# divide generators to strategic (set x) and non-strategic (set y)
set z / set.n.set.u /;
set x / n1.u1 /;
set y(n,u);

y(n,u) = z(n,u)-x(n,u);

*------------------------------------------------------------------------------*
* Scenario probabilities
*------------------------------------------------------------------------------*

Parameter w(s)
    /
    s1 0.25
    s2 0.25
    s3 0.25
    s4 0.25
    /
;

*------------------------------------------------------------------------------*
* Demand parameters in GW (All parameters are in GW or €/GW)
*------------------------------------------------------------------------------*

Table t_d_da(s,n)
    n1  n2  n3
s1  2   2   2
s2  3   3   3
s3  6   6   6
s4  6   6   6
;

Table t_d_intra(s,n)
    n1  n2  n3
s1  0   0   0
s2  2   2   2
s3  -4  -2  -2
s4  -5  -2  -2
;

Parameter d_da(s,n);
        d_da(s,n) = t_d_da(s,n);

Parameter d_intra(s,n);
        d_intra(s,n) = t_d_intra(s,n);

*------------------------------------------------------------------------------*
* Power generation parameters
*------------------------------------------------------------------------------*

Table t_da_cost(n,u)        day-ahead costs
        u1      u2      u3
n1      5      
n2              6
n3                      7       
;

Table t_up_cost(n,u)        up-regulation costs
        u1      u2      u3
n1      5      
n2              10
n3                      15       
;

Table t_down_cost(n,u)        down-regulation costs
        u1      u2      u3
n1      5      
n2              4
n3                      3       
;


Parameter
        c_da(n,u,b)         marginal cost of generation in the day-ahead market of unit u at node n
        c_up(n,u,b)         up-regulation costs of generation unit u at node n
        c_down(n,u,b)       down-regulation costs of generation unit u at node n;

        c_da(n,u,b) = t_da_cost(n,u);
        c_up(n,u,b) = t_up_cost(n,u);
        c_down(n,u,b) = t_down_cost(n,u);

Table t_gen_max(n,u) table for maximum generation capacity of generation unit u at node n
        u1      u2      u3
n1      5      
n2              5
n3                      5       
;

Parameter gen_max(n,u,b)  maximum generation capacity with generation unit u at node n;
        gen_max(n,u,b) = t_gen_max(n,u);

*------------------------------------------------------------------------------*
* Transmission line parameters
*------------------------------------------------------------------------------*

Table incidence(l,n)    matches power lines and start-end nodes
      n1      n2      n3
l1    -1      1       0
l2    0       -1      1
l3    -1      0       1
;

Parameter flow_max(l)
    /
    l1      1
    l2      1
    l3      1
    /
;

Parameter flow_min(l)
    /
    l1      -1
    l2      -1
    l3      -1
    /
;

*------------------------------------------------------------------------------*
* Discretize generation levels
*------------------------------------------------------------------------------*

Parameter interval;
interval = gen_max('n1','u1','b1')/(card(i)-1)

Parameter g_da_bar(b,i);
g_da_bar(b,'i1') = 0;
loop(i$(ord(i) < card(i)), g_da_bar(b,i+1) = g_da_bar(b,i) + interval;);

Parameter g_up_bar(b,j);
g_up_bar(b,'j1') = 0;
loop(j$(ord(j) < card(j)), g_up_bar(b,j+1) = g_up_bar(b,j) + interval;);

Parameter g_down_bar(b,k);
g_down_bar(b,'k1') = 0;
loop(k$(ord(k) < card(k)), g_down_bar(b,k+1) = g_down_bar(b,k) + interval;);

*------------------------------------------------------------------------------*
* Scalars for disjunctive constraints and setting bounds for bid prices
*------------------------------------------------------------------------------*
Scalars da_min_price /-500/, da_max_price /3000/, intra_max_price /3000/, intra_min_price /-500/;

Parameter K1, K2, K3, K4, K5, K6, K7, K8, K9, K10, M, K_da, K_up, K_down, Kv_da, Kv_up, Kv_down;
K1 = da_max_price*gen_max('n1','u1','b1');
K2 = da_max_price*gen_max('n1','u1','b1');
K3 = da_max_price*gen_max('n1','u1','b1');
K4 = da_max_price*gen_max('n1','u1','b1');
K5 = da_max_price*gen_max('n1','u1','b1');
K6 = da_max_price*gen_max('n1','u1','b1');
K7 = da_max_price*gen_max('n1','u1','b1');
K8 = da_max_price*gen_max('n1','u1','b1');
K9 = da_max_price*gen_max('n1','u1','b1');
K10 = da_max_price*gen_max('n1','u1','b1');
M = da_max_price*gen_max('n1','u1','b1');
K_da = da_max_price*gen_max('n1','u1','b1');
K_up = da_max_price*gen_max('n1','u1','b1');
K_down = da_max_price*gen_max('n1','u1','b1');
Kv_da = da_max_price*gen_max('n1','u1','b1');
Kv_up = da_max_price*gen_max('n1','u1','b1');
Kv_down = da_max_price*gen_max('n1','u1','b1');

*------------------------------------------------------------------------------*
* Variables
*------------------------------------------------------------------------------*

Variables
obj                         objective function value
lambda_da(s,n)              dual for day-ahead market power balance
lambda_intra(s,n)           dual for intraday market power balance
p_da(b)                     price offer of the strategic producer for the day-ahead market
p_up(b)                     price offer of the strategic producer for up-regulation
p_down(b)                   price offer of the strategic producer for down-regulation
v_da(s,b,i)                 discretization of the term lambda_da*g^da_s_p
v_up(s,b,j)                 discretization of the term lambda_intra*g^up_s_p
v_down(s,b,k)               discretization of the term lambda_intra*g^down_s_p
f_da(s,l)                   flow in the day-ahead market
f_intra(s,l)                flow in the intraday market
;

Positive Variables
q_da(b)                     volume offer of the strategic producer for the day-ahead market
g_da(s,n,u,b)               day-ahead generation
g_up(s,n,u,b)               up-regulation
g_down(s,n,u,b)             down-regulation
beta_da(s,n,u,b)            dual for maximum generation in day-ahead market
beta_up(s,n,u,b)            dual for maximum up-regulation
beta_down(s,n,u,b)          dual for maximum down-regulation
mu_da_p(s,l)                dual for maximum day-ahead flow
mu_da_n(s,l)                dual for minimum day-ahead flow
mu_intra_p(s,l)             dual for maximum intraday flow
mu_intra_n(s,l)             dual for minimum intraday flow
;

Binary Variables
r1(s,n,u,b)                 disjunctive variables
r2(s,n,u,b)
r3(s,l)
r4(s,l)
r5(s,n,u,b)
r6(s,n,u,b)
r7(s,n,u,b)
r8(s,n,u,b)
r9(s,l)
r10(s,l)
qq_da(s,b,i)                linearization variable for selecting i:th day-ahead generation level
qq_up(s,b,j)                linearization variable for selecting j:th up-regulation level
qq_down(s,b,k)              linearization variable for selecting j:th down-regulation level
up(s)                       restrict regulation only to one direction at a time
;

*------------------------------------------------------------------------------*
* Equations
*------------------------------------------------------------------------------*

Equations   
    Objective,
    Linear_DA_Level, Linear_Up_Level, Linear_Down_Level, Linear_DA_Level_Select, Linear_Up_Level_Select, Linear_Down_Level_Select,
    Linear_DA_Drive1, Linear_DA_Drive2, Linear_DA_Drive3, Linear_DA_Drive4,
    Linear_Up_Drive1, Linear_Up_Drive2, Linear_Up_Drive3, Linear_Up_Drive4,
    Linear_Down_Drive1, Linear_Down_Drive2, Linear_Down_Drive3, Linear_Down_Drive4,
    DA_Min_Offer_Price, DA_Max_Offer_Price,
    Intra_Max_Offer_Price1, Intra_Max_Offer_Price2, Intra_Max_Offer_Price3,
    Intra_Min_Offer_Price1, Intra_Min_Offer_Price2, Intra_Min_Offer_Price3,
    Max_Offer_Volume,
    Price_Offer1, Price_Offer2, Price_Offer3,
    DA_Gen1, DA_Gen2, DA_Gen3, 
    DA_Flow,
    DA_Balance,
    DA_Max_Gen1, DA_Max_Gen2, DA_Max_Gen3,
    DA_Max_Flow1, DA_Max_Flow2, DA_Max_Flow3,
    DA_Min_Flow1, DA_Min_Flow2, DA_Min_Flow3,
    Intra_Up1, Intra_Up2, Intra_Up3,
    Intra_Down1, Intra_Down2, Intra_Down3,
    Intra_Flow,
    Intra_Balance,
    Intra_Max_Up1, Intra_Max_Up2, Intra_Max_Up3,
    Intra_Max_Down1, Intra_Max_Down2, Intra_Max_Down3,
    Intra_Max_Flow1, Intra_Max_Flow2, Intra_Max_Flow3,
    Intra_Min_Flow1, Intra_Min_Flow2, Intra_Min_Flow3,
    Reg_Direction1, Reg_Direction2
;

################# Upper-level: bidding strategy

Objective..
    obj =e= sum(s, w(s)*(sum((n,u,b)$(x(n,u)), c_da(n,u,b)*g_da(s,n,u,b) + c_up(n,u,b)*g_up(s,n,u,b) - c_down(n,u,b)*g_down(s,n,u,b))
             - sum((b,i), v_da(s,b,i)) - sum((b,j), v_up(s,b,j)) + sum((b,k), v_down(s,b,k)) ));

# Linearization: Define generation levels and select exactly one

Linear_DA_Level(s,n,u,b)$(x(n,u))..
    g_da(s,n,u,b) =e= sum(i, qq_da(s,b,i)*g_da_bar(b,i));

Linear_Up_Level(s,n,u,b)$(x(n,u))..
    g_up(s,n,u,b) =e= sum(j, qq_up(s,b,j)*g_up_bar(b,j));

Linear_Down_Level(s,n,u,b)$(x(n,u))..
    g_down(s,n,u,b) =e= sum(k, qq_down(s,b,k)*g_down_bar(b,k));

Linear_DA_Level_Select(s,b)..
    sum(i, qq_da(s,b,i)) =e= 1;

Linear_Up_Level_Select(s,b)..
    sum(j, qq_up(s,b,j)) =e= 1;

Linear_Down_Level_Select(s,b)..
    sum(k, qq_down(s,b,k)) =e= 1;

# Linearization: Model the bilinear terms g_da*lambda_da by v_da which is forced to be zero or g_da_bar*lambda_da

# Day-ahead generation

Linear_DA_Drive1(s,b,i)..
    v_da(s,b,i) =l= K_da*qq_da(s,b,i);

Linear_DA_Drive2(s,b,i)..
    v_da(s,b,i) =g= -K_da*qq_da(s,b,i);

Linear_DA_Drive3(s,b,i)..
    v_da(s,b,i) =l= g_da_bar(b,i)*lambda_da(s,'n1') + K_da*(1-qq_da(s,b,i));

Linear_DA_Drive4(s,b,i)..
    v_da(s,b,i) =g= g_da_bar(b,i)*lambda_da(s,'n1') - K_da*(1-qq_da(s,b,i));

# Up-regulation

Linear_Up_Drive1(s,b,j)..
    v_up(s,b,j) =l= K_up*qq_up(s,b,j);

Linear_Up_Drive2(s,b,j)..
    v_up(s,b,j) =g= -K_up*qq_up(s,b,j);

Linear_Up_Drive3(s,b,j)..
    v_up(s,b,j) =l= g_up_bar(b,j)*lambda_intra(s,'n1') + K_up*(1-qq_up(s,b,j));

Linear_Up_Drive4(s,b,j)..
    v_up(s,b,j) =g= g_up_bar(b,j)*lambda_intra(s,'n1') - K_up*(1-qq_up(s,b,j));

# Down-regulation

Linear_Down_Drive1(s,b,k)..
    v_down(s,b,k) =l= K_down*qq_down(s,b,k);

Linear_Down_Drive2(s,b,k)..
    v_down(s,b,k) =g= -K_down*qq_down(s,b,k);

Linear_Down_Drive3(s,b,k)..
    v_down(s,b,k) =l= g_down_bar(b,k)*lambda_intra(s,'n1') + K_down*(1-qq_down(s,b,k));

Linear_Down_Drive4(s,b,k)..
    v_down(s,b,k) =g= g_down_bar(b,k)*lambda_intra(s,'n1') - K_down*(1-qq_down(s,b,k));

# Miscellaneous constraints for the upper-level such as the price offer limits

DA_Min_Offer_Price(b)..
    p_da(b) =g= da_min_price;

DA_Max_Offer_Price(b)..
    p_da(b) =l= da_max_price;

Intra_Max_Offer_Price1(b)..
    p_up(b) =l= intra_max_price;

Intra_Max_Offer_Price2(b)..
    p_up(b) =g= intra_min_price;

Intra_Max_Offer_Price3(b)..
    p_down(b) =l= p_da(b);

Intra_Min_Offer_Price1(b)..
    p_down(b) =g= intra_min_price;

Intra_Min_Offer_Price2(b)..
    p_down(b) =l= intra_max_price;

Intra_Min_Offer_Price3(b)..
    p_up(b) =g= p_da(b);

Max_Offer_Volume(n,u,b)$(x(n,u))..
    q_da(b) =l= gen_max(n,u,b);

Reg_Direction1(s,n,u,b)$(x(n,u))..
    g_up(s,n,u,b) =l= up(s)*M;

Reg_Direction2(s,n,u,b)$(x(n,u))..
    g_down(s,n,u,b) =l= (1-up(s))*M;

Price_Offer1(b)$(ord(b)>1)..
    p_da(b) =g= p_da(b-1);

Price_Offer2(b)$(ord(b)>1)..
    p_up(b) =g= p_up(b-1);

Price_Offer3(b)$(ord(b)>1)..
    p_down(b) =g= p_down(b-1);

################# Lower-level 1: Day-ahead market dispatch

DA_Gen1(s,n,u,b).. # the derivative of the lower-level problem w.r.t. g^da
    p_da(b)$(x(n,u)) + c_da(n,u,b)$(y(n,u)) - lambda_da(s,n) + beta_da(s,n,u,b) =g= 0;

DA_Gen2(s,n,u,b)..
    p_da(b)$(x(n,u)) + c_da(n,u,b)$(y(n,u)) - lambda_da(s,n) + beta_da(s,n,u,b) =l= K1*r1(s,n,u,b);

DA_Gen3(s,n,u,b)..
    g_da(s,n,u,b) =l= K1*(1-r1(s,n,u,b));

DA_Flow(s,l).. # w.r.t. f^da
    - sum(n, incidence(l,n)*lambda_da(s,n)) + mu_da_p(s,l) - mu_da_n(s,l) =e= 0;

DA_Balance(s,n).. # day-ahead balance: supply + imports = demand + exports
    d_da(s,n) - sum((u,b), g_da(s,n,u,b)) - sum(l, incidence(l,n)*f_da(s,l)) =e= 0;

DA_Max_Gen1(s,n,u,b).. # perp to beta^da
    q_da(b)$(x(n,u)) + gen_max(n,u,b)$(y(n,u)) - g_da(s,n,u,b) =g= 0;

DA_Max_Gen2(s,n,u,b)..
    q_da(b)$(x(n,u)) + gen_max(n,u,b)$(y(n,u)) - g_da(s,n,u,b) =l= K2*r2(s,n,u,b);

DA_Max_Gen3(s,n,u,b)..
    beta_da(s,n,u,b) =l= K2*(1-r2(s,n,u,b));

DA_Max_Flow1(s,l).. # perp to mu^da_p
    flow_max(l) - f_da(s,l) =g= 0;

DA_Max_Flow2(s,l)..
    flow_max(l) - f_da(s,l) =l= K3*r3(s,l);

DA_Max_Flow3(s,l)..
    mu_da_p(s,l) =l= K3*(1-r3(s,l));

DA_Min_Flow1(s,l).. # perp to mu^da_n
    f_da(s,l) - flow_min(l) =g= 0;

DA_Min_Flow2(s,l)..
    f_da(s,l) - flow_min(l) =l= K4*r4(s,l);

DA_Min_Flow3(s,l)..
    mu_da_n(s,l) =l= K4*(1-r4(s,l));

################# Lower-level 1: Intraday market dispatch

Intra_Up1(s,n,u,b).. # w.r.t. g^up
    p_up(b)$(x(n,u)) + c_up(n,u,b)$(y(n,u)) - lambda_intra(s,n) + beta_up(s,n,u,b) =g= 0;

Intra_Up2(s,n,u,b)..
    p_up(b)$(x(n,u)) + c_up(n,u,b)$(y(n,u)) - lambda_intra(s,n) + beta_up(s,n,u,b) =l= K5*r5(s,n,u,b);

Intra_Up3(s,n,u,b)..
    g_up(s,n,u,b) =l= K5*(1-r5(s,n,u,b));

Intra_Down1(s,n,u,b).. # w.r.t. g^down
    - p_down(b)$(x(n,u)) - c_down(n,u,b)$(y(n,u)) + lambda_intra(s,n) + beta_down(s,n,u,b) =g= 0;

Intra_Down2(s,n,u,b)..
    - p_down(b)$(x(n,u)) - c_down(n,u,b)$(y(n,u)) + lambda_intra(s,n) + beta_down(s,n,u,b) =l= K6*r6(s,n,u,b);

Intra_Down3(s,n,u,b)..
    g_down(s,n,u,b) =l= K6*(1-r6(s,n,u,b));

Intra_Flow(s,l).. # w.r.t. f^intra
    - sum(n, incidence(l,n)*lambda_intra(s,n)) + mu_intra_p(s,l) - mu_intra_n(s,l) =e= 0;

Intra_Balance(s,n)..
    d_intra(s,n) - sum((u,b), g_up(s,n,u,b) - g_down(s,n,u,b)) - sum(l, incidence(l,n)*f_intra(s,l)) =e= 0;

Intra_Max_Up1(s,n,u,b).. # perp to beta^up
    gen_max(n,u,b) - g_da(s,n,u,b) - g_up(s,n,u,b) =g= 0;

Intra_Max_Up2(s,n,u,b)..
    gen_max(n,u,b) - g_da(s,n,u,b) - g_up(s,n,u,b) =l= K7*r7(s,n,u,b);

Intra_Max_Up3(s,n,u,b)..
    beta_up(s,n,u,b) =l= K7*(1-r7(s,n,u,b));

Intra_Max_Down1(s,n,u,b).. # perp to beta^down
    g_da(s,n,u,b) - g_down(s,n,u,b) =g= 0;

Intra_Max_Down2(s,n,u,b)..
    g_da(s,n,u,b) - g_down(s,n,u,b) =l= K8*r8(s,n,u,b);

Intra_Max_Down3(s,n,u,b)..
    beta_down(s,n,u,b) =l= K8*(1-r8(s,n,u,b));

Intra_Max_Flow1(s,l).. # perp to mu^da_p
    flow_max(l) - f_da(s,l) - f_intra(s,l) =g= 0;

Intra_Max_Flow2(s,l)..
    flow_max(l) - f_da(s,l) - f_intra(s,l) =l= K9*r9(s,l);

Intra_Max_Flow3(s,l)..
    mu_intra_p(s,l) =l= K9*(1-r9(s,l));

Intra_Min_Flow1(s,l).. # perp to mu^da_n
    f_da(s,l) + f_intra(s,l) - flow_min(l) =g= 0;

Intra_Min_Flow2(s,l)..
    f_da(s,l) + f_intra(s,l) - flow_min(l) =l= K10*r10(s,l);

Intra_Min_Flow3(s,l)..
    mu_intra_n(s,l) =l= K10*(1-r10(s,l));


Model master_mip
    /   
    Objective,
    Linear_DA_Level, Linear_Up_Level, Linear_Down_Level, Linear_DA_Level_Select, Linear_Up_Level_Select, Linear_Down_Level_Select,
    Linear_DA_Drive1, Linear_DA_Drive2, Linear_DA_Drive3, Linear_DA_Drive4,
    Linear_Up_Drive1, Linear_Up_Drive2, Linear_Up_Drive3, Linear_Up_Drive4,
    Linear_Down_Drive1, Linear_Down_Drive2, Linear_Down_Drive3, Linear_Down_Drive4,
    DA_Min_Offer_Price, DA_Max_Offer_Price,
    Intra_Max_Offer_Price1, Intra_Max_Offer_Price2, Intra_Max_Offer_Price3,
    Intra_Min_Offer_Price1, Intra_Min_Offer_Price2, Intra_Min_Offer_Price3,
    Max_Offer_Volume,
    Price_Offer1, Price_Offer2, Price_Offer3,
    DA_Gen1, DA_Gen2, DA_Gen3, 
    DA_Flow,
    DA_Balance,
    DA_Max_Gen1, DA_Max_Gen2, DA_Max_Gen3,
    DA_Max_Flow1, DA_Max_Flow2, DA_Max_Flow3,
    DA_Min_Flow1, DA_Min_Flow2, DA_Min_Flow3,
    Intra_Up1, Intra_Up2, Intra_Up3,
    Intra_Down1, Intra_Down2, Intra_Down3,
    Intra_Flow,
    Intra_Balance,
    Intra_Max_Up1, Intra_Max_Up2, Intra_Max_Up3,
    Intra_Max_Down1, Intra_Max_Down2, Intra_Max_Down3,
    Intra_Max_Flow1, Intra_Max_Flow2, Intra_Max_Flow3,
    Intra_Min_Flow1, Intra_Min_Flow2, Intra_Min_Flow3,
    Reg_Direction1, Reg_Direction2
    /
;

#option mip = cplex;
#master_mip.optfile=1;
option reslim=100000000;

# Solve the problem
Solve master_mip using mip minimizing obj;

# Show results
display obj.l;
display p_da.l, q_da.l, g_da.l, lambda_da.l;
display p_up.l, p_down.l, g_up.l, g_down.l, lambda_intra.l, f_da.l, f_intra.l;
display v_da.l, v_up.l, v_down.l;
display beta_da.l;