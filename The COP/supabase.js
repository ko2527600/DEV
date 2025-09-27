// supabaseBackend.js
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm';

// ===== Supabase credentials =====
const SUPABASE_URL = 'https://pdkoeedcsdwsnfyfipcx.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBka29lZWRjc2R3c25meWZpcGN4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgyNTU0NTAsImV4cCI6MjA2MzgzMTQ1MH0.eO5CHZtPB_pqAcR0G4bzw_56SQgqLULYJvgdwEVTlmk';

// ===== Create Supabase client =====
export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ===== Function to fetch videos from 'videos' table =====
export async function getVideos() {
  const { data, error } = await supabase.from('videos').select('*');
  if (error) throw error;
  return data;
}

// ===== Function to upload video metadata =====
export async function uploadVideo(videoData) {
  const { data, error } = await supabase.from('videos').insert([videoData]);
  if (error) throw error;
  return data;
}



// ===== Function to fetch files from 'videos' storage bucket =====
export async function getVideosFromStorage() {
  const { data, error } = await supabase.storage.from('videos').list('', { sortBy: { column: 'name', order: 'asc' } });
  if (error) throw error;
  return data;
}

// ===== Function to display gallery images =====
export async function displayGalleryImages() {
  const galleryContainer = document.getElementById('gallery-container');
  if (!galleryContainer) return;

  try {
    const files = await getGalleryFiles();
    console.log('Fetched gallery files:', files);

    if (files && files.length > 0) {
      galleryContainer.innerHTML = ''; // Clear "Loading..." message
      files.forEach(file => {
        const { data: publicUrlData } = supabase.storage.from('gallery').getPublicUrl(file.name);
        const imageUrl = publicUrlData.publicUrl;

        const imageElement = document.createElement('div');
        imageElement.classList.add('gallery-item');
        imageElement.innerHTML = `
          <img src="${imageUrl}" alt="${file.name}">
          <p>${file.name}</p>
        `;
        galleryContainer.appendChild(imageElement);
      });
    } else {
      galleryContainer.innerHTML = '<p>No gallery images found.</p>';
    }
  } catch (error) {
    console.error('Error fetching gallery images:', error.message);
    galleryContainer.innerHTML = `<p>Error loading gallery images: ${error.message}</p>`;
  }
}

// ===== Function to display videos from storage =====
export async function displayVideos() {
    const videosContainer = document.getElementById('videos-content');
    if (!videosContainer) return;

    try {
        const files = await getVideosFromStorage();
        console.log('Fetched video files:', files);

        if (files && files.length > 0) {
            videosContainer.innerHTML = '<div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6" id="video-grid"></div>'; // Create a grid container
            const videoGrid = document.getElementById('video-grid');

            files.forEach(file => {
                const { data: publicUrlData } = supabase.storage.from('videos').getPublicUrl(file.name);
                const videoUrl = publicUrlData.publicUrl;

                const videoElement = document.createElement('div');
                videoElement.classList.add('video-item', 'bg-white', 'rounded-xl', 'shadow', 'p-4');
                videoElement.innerHTML = `
                    <div class="aspect-video mb-4">
                        <video controls class="w-full h-full rounded-lg">
                            <source src="${videoUrl}" type="video/mp4">
                            Your browser does not support the video tag.
                        </video>
                    </div>
                    <h3 class="font-semibold text-lg text-gray-800 mb-2">${file.name}</h3>
                    <p class="text-sm text-gray-600">Uploaded: ${new Date(file.created_at).toLocaleDateString()}</p>
                `;
                videoGrid.appendChild(videoElement);
            });
        } else {
            videosContainer.innerHTML = '<p>No videos found.</p>';
        }
    } catch (error) {
        console.error('Error fetching videos:', error.message);
        videosContainer.innerHTML = `<p>Error loading videos: ${error.message}</p>`;
    }
}

// Add more functions as needed: deleteVideo, getUsers, uploadImage, etc.
