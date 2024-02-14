const CLOUDFRONT_STREAM_BASE_URL = 'https://d3mgzcs3lrwvom.cloudfront.net/';
const CLOUDFRONT_IMAGE_BASE_URL = 'https://dc666cmbq88s6.cloudfront.net/';

export function getImageURL(user, imageId) {
  return CLOUDFRONT_IMAGE_BASE_URL + `${user.email.replace('@', '%40')}/${imageId}.jpg`;
}

export function getVideoHLSURL(user, videoId) {
  return CLOUDFRONT_STREAM_BASE_URL + `${user.email.replace('@', '%40')}/${videoId}/output/HLS/${videoId}`;
}

export function getVideoThumbnailURL(user, videoId) {
  return CLOUDFRONT_STREAM_BASE_URL + `${user.email.replace('@', '%40')}/${videoId}/output/Thumbnails/${videoId}.0000000.jpg`;
}
