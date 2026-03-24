import SwiftUI

struct WalletView: View {
    @StateObject private var viewModel = WalletViewModel()
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showReceive = false
    @State private var showSend = false
    
    var body: some View {
        ZStack {
            AppTheme.shared.background(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                WalletHeaderView(
                    balance: authService.currentUser?.walletBalance ?? 0
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                        HStack(spacing: 16) {
                            ActionButton(
                                title: "Receive",
                                icon: "qrcode",
                                color: AppTheme.shared.green
                            ) {
                                showReceive = true
                            }
                            
                            ActionButton(
                                title: "Send",
                                icon: "arrow.up.circle",
                                color: AppTheme.shared.blue
                            ) {
                                showSend = true
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        LightningAddressCard(
                            address: authService.currentUser?.lightningAddress
                        )
                        .padding(.horizontal, 16)
                        
                        TransactionListView(
                            transactions: viewModel.transactions,
                            isLoading: viewModel.isLoading
                        )
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showReceive) {
            ReceiveView()
        }
        .sheet(isPresented: $showSend) {
            SendView()
        }
        .task {
            await viewModel.loadTransactions()
        }
    }
}

struct WalletHeaderView: View {
    let balance: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Text("Lightning Wallet")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            VStack(spacing: 4) {
                Text("Total Balance")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.8))
                
                Text("\(balance.formatted()) sats")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                Text("≈ $\(String(format: "%.2f", Double(balance) * 0.0004)) USD")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.8))
            }
            .padding(.vertical, 16)
        }
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    AppTheme.shared.snYellow,
                    AppTheme.shared.snYellowDark
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}

struct LightningAddressCard: View {
    let address: String?
    @Environment(\.colorScheme) var colorScheme
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lightning Address")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
            
            HStack {
                Text(address ?? "Not set")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
                
                Spacer()
                
                Button(action: copyAddress) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.shared.snYellow)
                }
            }
            .padding(12)
            .background(AppTheme.shared.background(for: colorScheme))
            .cornerRadius(8)
        }
        .padding(16)
        .background(AppTheme.shared.cardBackground(for: colorScheme))
        .cornerRadius(16)
    }
    
    private func copyAddress() {
        guard let address = address else { return }
        UIPasteboard.general.string = address
        copied = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
}

struct TransactionListView: View {
    let transactions: [LightningTransaction]
    let isLoading: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
                .padding(.horizontal, 16)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if transactions.isEmpty {
                Text("No transactions yet")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(transactions) { tx in
                        TransactionRow(transaction: tx)
                    }
                }
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: LightningTransaction
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    transaction.type == .receive
                        ? Color.green.opacity(0.2)
                        : Color.red.opacity(0.2)
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: transaction.type == .receive ? "arrow.down" : "arrow.up")
                        .font(.subheadline)
                        .foregroundColor(
                            transaction.type == .receive ? .green : .red
                        )
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description ?? (transaction.type == .receive ? "Received" : "Sent"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.shared.textPrimary(for: colorScheme))
                
                Text(transaction.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transaction.type == .receive ? "+" : "-")\(transaction.amount) sats")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.type == .receive ? .green : .red)
                
                Text("$\(String(format: "%.2f", Double(transaction.amount) * 0.0004))")
                    .font(.caption)
                    .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.shared.cardBackground(for: colorScheme))
    }
}

class WalletViewModel: ObservableObject {
    @Published var transactions: [LightningTransaction] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let api = APIClient.shared
    
    func loadTransactions() async {
        await MainActor.run { isLoading = true }
        
        do {
            let txs = try await api.getTransactions()
            await MainActor.run {
                self.transactions = txs
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

struct ReceiveView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var amount = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount (sats)")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                    
                    TextField("1000", text: $amount)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(AppTheme.shared.cardBackground(for: colorScheme))
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (optional)")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                    
                    TextField("What's this for?", text: $description)
                        .padding()
                        .background(AppTheme.shared.cardBackground(for: colorScheme))
                        .cornerRadius(12)
                }
                
                Button(action: generateInvoice) {
                    Text("Generate Invoice")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.shared.snYellow)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding(24)
            .background(AppTheme.shared.background(for: colorScheme).ignoresSafeArea())
            .navigationTitle("Receive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func generateInvoice() {
    }
}

struct SendView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var invoice = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lightning Invoice")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.shared.textSecondary(for: colorScheme))
                    
                    TextField("lnbc...", text: $invoice)
                        .padding()
                        .background(AppTheme.shared.cardBackground(for: colorScheme))
                        .cornerRadius(12)
                }
                
                HStack(spacing: 12) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                            Text("Scan QR")
                        }
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.shared.cardBackground(for: colorScheme))
                        .foregroundColor(AppTheme.shared.snYellow)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "doc.on.clipboard")
                            Text("Paste")
                        }
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.shared.cardBackground(for: colorScheme))
                        .foregroundColor(AppTheme.shared.snYellow)
                        .cornerRadius(12)
                    }
                }
                
                Button(action: payInvoice) {
                    Text("Pay Invoice")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(invoice.isEmpty ? Color.gray : AppTheme.shared.snYellow)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
                .disabled(invoice.isEmpty)
                
                Spacer()
            }
            .padding(24)
            .background(AppTheme.shared.background(for: colorScheme).ignoresSafeArea())
            .navigationTitle("Send")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func payInvoice() {
    }
}

#Preview {
    WalletView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(AuthService.shared)
}
