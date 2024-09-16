import pandas as pd
import matplotlib.pyplot as plt
from sklearn.neighbors import LocalOutlierFactor
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import confusion_matrix, accuracy_score, precision_score, recall_score, f1_score

# Load the datasets
# data3 = pd.read_csv('D://Python_Code//Stori//Data3.csv')
ledger = pd.read_csv('D://Python_Code//Stori//ledger3.csv')
# ledger = pd.read_csv('D://Python_Code//Stori//ledger5.csv')

# Merge datasets on 'external_acct_id' from Data3 and 'indra_external_acct_id' from ledger table
# combined_data = pd.merge(data3, ledger1, left_on='external_acct_id', right_on='indra_external_acct_id', how='inner')

# # Merge datasets on 'external_acct_id' from Data3 and '_acct_id' from ledger table
# combined_data = pd.merge(data3, ledger1, left_on='external_acct_id', right_on='acct_id', how='inner')

features = ['tot_pmt_cnt', 'tot_pmt_amt', 'start_posted_bal_amt']
X = ledger[features]
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)
lof = LocalOutlierFactor(n_neighbors=100, novelty=False, contamination=0.01)
outliers = lof.fit_predict(X_scaled)

amt_mean_value = ledger['tot_pmt_amt'].mean()
amt_std_value = ledger['tot_pmt_amt'].std()

for i, (amt, bal_amt) in enumerate(zip(X['tot_pmt_amt'], X['start_posted_bal_amt'])):
    # Case 1: Positive Start Posted Balance with Positive Total Payment Amount
    if bal_amt > 0 and amt > 0:
        if amt < bal_amt * 1.5:
            outliers[i] = 1  # Set as inlier
        # elif bal_amt < amt_mean_value or amt< amt_mean_value:
        #     outliers[i] = 1

    # Case 2: Negative Start Posted Balance with Positive Total Payment Amount
    if bal_amt < 0 and amt > 0:
        if amt <= abs(bal_amt) * 1.1:
            outliers[i] = 1

# Visualization
plt.title("Abnormal Detection with LOF using multiple features")
plt.scatter(X_scaled[:, 0], X_scaled[:, 1], c=outliers, cmap='coolwarm', edgecolor='k', label='Inlier')
plt.colorbar(label='Outlier (-1) Inlier (+1)')
plt.legend()
plt.xlabel(features[0])
plt.ylabel(features[1])
plt.show()

# Adding outlier detection results to the data
ledger['outlier'] = outliers
abnormal_transactions = ledger[ledger['outlier'] == -1]

pd.set_option('display.max_columns', None)
pd.set_option('display.max_colwidth', None)
pd.set_option('display.width', 1000)
print("Detected Abnormal Transactions:")
print(abnormal_transactions[['external_acct_id', 'accounting_date', 'tot_pmt_cnt', 'tot_pmt_amt', 'start_posted_bal_amt', 'outlier']])

###################################################################
# False positive/False Positive rate
n = 2   # n is the parameter used in μ + n * σ
threshold = amt_mean_value + n * amt_std_value

# Classify as outlier (-1 for outlier, 1 for inlier) based on threshold
ledger['threshold_outlier'] = (ledger['tot_pmt_amt'] > threshold).astype(int)
ledger['outlier'] = (ledger['outlier']== -1).astype(int)

accuracy = accuracy_score(ledger['threshold_outlier'], ledger['outlier'])
tp, fp, fn, tn = confusion_matrix(ledger['threshold_outlier'], ledger['outlier']).ravel()

# Calculate false positive rate (FPR) and false negative rate (FNR)
fpr = fp / (fp + tn)
fnr = fn / (fn + tp)

print(f"Accuracy: {accuracy:.2f}")
print(f"False Positive Rate: {fpr:.2f}")
print(f"False Negative Rate: {fnr:.2f}")

# Identify and print all false positives
false_positives = ledger[(ledger['threshold_outlier'] == 0) & (ledger['outlier'] == 1)]

pd.set_option('display.max_columns', None)
pd.set_option('display.max_colwidth', None)
pd.set_option('display.width', 1000)
print("False Positive Transactions:")
print(false_positives[['external_acct_id', 'accounting_date', 'tot_pmt_cnt', 'tot_pmt_amt', 'start_posted_bal_amt', 'outlier', 'threshold_outlier']])

# Calculate precision, recall, and F1 score
precision = precision_score(ledger['threshold_outlier'], ledger['outlier'])
recall = recall_score(ledger['threshold_outlier'], ledger['outlier'])
f1 = f1_score(ledger['threshold_outlier'], ledger['outlier'])

print(f"Precision: {precision:.2f}")
print(f"Recall: {recall:.2f}")
print(f"F1 Score: {f1:.2f}")