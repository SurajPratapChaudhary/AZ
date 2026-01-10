
import SwiftUI

struct StudioMusicSheet: View {
    @State private var selectedCategory: String = "Luxury"
    
    let categories = ["Luxury", "Cinematic", "Clean", "Editorial", "Upbeat"]
    
    // Mock Data based on screenshot
    let tracks: [MusicTrack] = [
        MusicTrack(id: "1", title: "Midnight Serenade", duration: "3:15"),
        MusicTrack(id: "2", title: "Dawn's Embrace", duration: "4:20"),
        MusicTrack(id: "3", title: "Afternoon Whispers", duration: "1:50"),
        MusicTrack(id: "4", title: "Twilight Reflections", duration: "5:30"),
        MusicTrack(id: "5", title: "Sunset Melodies", duration: "6:10"),
        MusicTrack(id: "6", title: "Nocturnal Rhythm", duration: "7:00")
    ]
    
    struct MusicTrack: Identifiable {
        let id: String
        let title: String
        let duration: String
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6).opacity(0.1).ignoresSafeArea() // Dark background
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                // Header (Sheet indicator is handled by presentationDragIndicator)
                
                Text("Add Sound Track")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                
                // Categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            Text(category)
                                .font(.system(size: 15, weight: .medium))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                                .background(selectedCategory == category ? Color("AccentColor") : Color.clear)
                                .foregroundStyle(selectedCategory == category ? .black : .gray)
                                .clipShape(Capsule())
                                .onTapGesture {
                                    withAnimation {
                                        selectedCategory = category
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Track List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(tracks) { track in
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color(UIColor.darkGray).opacity(0.3))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "music.note")
                                        .foregroundStyle(.gray)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(track.title)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.white)
                                    Text(track.duration)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.gray)
                            }
                            .padding(16)
                            .background(Color(UIColor.secondarySystemBackground).opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}
