//
//  ContentView.swift
//  DadJokes
//
//  Created by Russell Gordon on 2022-02-21.
//

import SwiftUI

struct ContentView: View {
    // MARK: Stored properties
    
    // Detect when an app moves between foreground, background, and inactive states
    // NOTE: A complete list of keypaths that can be used with @environment can be found here:
    // https://developer.apple.com/documentation/swiftui/environmentvalues
    
    @Environment(\.scenePhase) var scenePhase
    @State var currentJoke: DadJoke = DadJoke(id: "",
                                              joke: "Knock, knock...",
                                              status: 0)
    // This will keep track of our list of favourite jokes
    @State var favourites: [DadJoke] = [] // empty list to start
    // This will let us know whether the current joke exists as a favourite
    @State var currenJokeAddedToFavourites = false
    
    // MARK: Computed properties
    var body: some View {
        VStack {
            Text(currentJoke.joke)
                .font(.title)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.leading)
                .padding(30)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary, lineWidth: 4)
                )
                .padding(10)
            Image(systemName: "heart.circle")
                .resizable()
                .frame(width: 35, height: 35)
                .foregroundColor(currenJokeAddedToFavourites ? .red : .secondary)
                .onTapGesture {
                    // Only add to the list if it is not already there
                    if !currenJokeAddedToFavourites {
                        // Adds the current joke to the list
                        favourites.append(currentJoke)
                        
                        // Record that we have marked this as a favourite
                        currenJokeAddedToFavourites = true
                    }
                }
            Button(action: {
                // The Task type allows us to run asynchronous code within a button and have the user interface be updated when the data is ready
                // Since it is asynchronous, other tasks can run while we wait for the data to come back from the web server
                Task {
                    // Call the function that will get us a new joke!
                    await loadNewJoke()
                }
            }, label: {
                Text("Another one!")
            })
                .buttonStyle(.bordered)
            HStack {
                Text("Favourites")
                    .bold()
                Spacer()
            }
            // Iterate over the list of favourites
            // As we iterate, each individual favourite is accessible via "currentFavourite"
            List(favourites, id: \.self) { currentFavourite in
                Text(currentFavourite.joke)
            }
            Spacer()
            
        }
        // When the app opens, get a new joke from the web service
        .task {
            // Load a joke from the endpoint!
            // We are "calling" or "invoking" the function named "loadNewJoke"
            // A term for this is the "call site" of a function
            // What does "await" mean?
            // This just means that we, as the programmer, are aware that this function is asynchronous
            // Results might come bac right away, or, take some time to complete
            // ALSO: Any code below this calll will run before the function call completes
            await loadNewJoke()
            print("I tried to load a new joke")
            // Load the favourites from the file saved on the device
            loadFavourites()
        }
        // React to changes of state for the app (foreground, background, inactive)
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .inactive {
                print("Inactive")
            } else if newPhase == .active {
                print("Active")
            } else {
                print("Background")
                // Permanently save the list of tasks
                persistFavourites()
            }
        }
        .navigationTitle("icanhazdadjoke?")
        .padding()
    }
    
    // MARK: Functions
    
    // Define the function "loadNewJoke"
    // Teaching our app to do a "new thing"
    // Using the "async" keyword means that this function can potentially be run alongside other tasks that the app needs to do (for example, updating the user interface)
    func loadNewJoke() async {
        // Assemble the URL that points to the endpoint
        let url = URL(string: "https://icanhazdadjoke.com/")!
        
        // Define the type of data we want from the endpoint
        // Configure the request to the web site
        var request = URLRequest(url: url)
        // Ask for JSON data
        request.setValue("application/json",
                         forHTTPHeaderField: "Accept")
        
        // Start a session to interact (talk with) the endpoint
        let urlSession = URLSession.shared
        
        // Try to fetch a new joke
        // It might not work, so we use a do-catch block
        do {
            
            // Get the raw data from the endpoint
            let (data, _) = try await urlSession.data(for: request)
            
            // Attempt to decode the raw data into a Swift structure
            // Takes what is in "data" and tries to put it into "currentJoke"
            //                                 DATA TYPE TO DECODE TO
            //                                         |
            //                                         V
            currentJoke = try JSONDecoder().decode(DadJoke.self, from: data)
            // Reset the flag that tracks whether the current joke is a favourite
            currenJokeAddedToFavourites = false
            
        } catch {
            print("Could not retrieve or decode the JSON from endpoint.")
            // Print the contents of the "error" constant that the do-catch block
            // populates
            print(error)
        }
    }
    // Save the data permanently
    func persistFavourites() {
        // Get a location under which to save the data
        let filename = getDocumentsDirectory().appendingPathComponent(savedFavouritesLabel)
        print(filename)
        // Try to encode the data in our list of favourites to JSON
        do {
            // Create a JSON Encoder object
            let encoder = JSONEncoder()
            // Configured the encoder to "pretty print" the JSON
            encoder.outputFormatting = .prettyPrinted
            //Encode the list of favourites we've collected
            let data = try encoder.encode(favourites)
            // Write the JSON to a file in the filename location we came up with earlier
            try data.write(to: filename, options: [.atomicWrite, .completeFileProtection])
            // See the data that was written
            print("Saved data to the Documents directory successfully.")
            print("==========")
            print(String(data: data, encoding: .utf8)!)
        } catch {
            print("Unable to write list of favourites to the Documents directory")
            print("===========")
            print(error.localizedDescription)
        }
    }
    // Lodas the data that was saved to the device
    // Loading our favourites...
    func loadFavourites() {
        // Get a location from which to load the data
        let filename = getDocumentsDirectory().appendingPathComponent(savedFavouritesLabel)
        print(filename)
        // Attempt to load the data
        do {
            // Load the raw data
            let data = try Data(contentsOf: filename)
            // See the data that was read
            print("Saved data to the Documents directory successfully.")
            print("==========")
            print(String(data: data, encoding: .utf8)!)
            // Decode the JSON into Swift native data structures
            // NOTE: We used [DadJoke] since we are loading into a list (array)
            favourites = try JSONDecoder().decode([DadJoke].self, from: data)
        } catch {
            // What went wrong?
            print("Could not load the data from the stored JSON file")
            print("========")
            print(error.localizedDescription)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContentView()
        }
    }
}
