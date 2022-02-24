//
//  SharedFunctionsAndConstants.swift
//  DadJokes
//
//  Created by Jacobo de Juan Millon on 2022-02-24.
//

import Foundation

// Return the location of the Documents directory for this app
func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    // Return the first path
    return paths[0]
}

// Define a filename (label) that we will write the data to in the directory
let savedFavouritesLabel =  "savedFavourites"
