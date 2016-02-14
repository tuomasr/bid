# bid
Model for the working paper "Strategic offering of a flexible producer in sequential day-ahead and intraday markets"

# Model description
The bi-level model builds offering curves of a strategic producer for sequential day-ahead and intraday markets. The upper-level maximizes the profit of the strategic producer, while the lower-level problems clear the day-ahead and intraday markets.

# Running the model
The model uses GAMS and CPLEX. Run the model with
```
gams bid.gms
```
