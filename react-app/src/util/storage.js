import { getUrl } from 'aws-amplify/storage';

export async function getImageUrl(key) {
    const urlResponse = await getUrl({
        key: key
    });

    if (urlResponse !== undefined) {
        return urlResponse.url.href;
    }

    return undefined;
}