import SwiftUI
import Combine

struct TextFieldAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var text: String
    var placeholder: String
    
    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    if isPresented {
                        Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 20) {
                            Text("Enter \(placeholder)")
                                .font(.headline)
                            
                            TextField(placeholder, text: $text)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                            
                            HStack {
                                Button("Cancel") {
                                    isPresented = false
                                }
                                
                                Button("OK") {
                                    isPresented = false
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                    }
                }
            )
    }
}

extension View {
    func textFieldAlert(isPresented: Binding<Bool>, text: Binding<String>, placeholder: String) -> some View {
        self.modifier(TextFieldAlertModifier(isPresented: isPresented, text: text, placeholder: placeholder))
    }
}
