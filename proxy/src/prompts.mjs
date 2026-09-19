// The three prompts the app used to carry, moved here unchanged. Because they
// live on the server, the app can only ask for these three fixed things.

export const CLASSIFY_PROMPT = `Analyze this image and determine if it contains a human or an animal.
Return ONLY a JSON object with this format:
{
  "contains_human": true/false,
  "contains_animal": true/false,
  "confidence": 0-100 (percentage of confidence in the classification)
}`;

export const IDENTIFY_PROMPT = `You are an expert zoologist and wildlife biologist. Carefully analyze this image of an animal and provide accurate identification.

I need you to:
1. Identify the animal's exact species with scientific name
2. Determine the breed or subspecies if applicable
3. Estimate the animal's age based on visual cues
4. Assess the animal's approximate health condition
5. Estimate the animal's weight in kilograms
6. Note any distinguishing or unique features visible in this specific animal
7. Determine current mood or state (alert, calm, playful, etc.)
8. Assess how rare or common this animal is

Return ONLY a JSON object with the following format (no additional text):
{
  "species": "Scientific name of the species",
  "common_name": "Common name people use for this animal",
  "breed": "Breed or subspecies if applicable, otherwise empty string",
  "estimated_age": "Age in years, can be a range if uncertain",
  "estimated_weight_kg": number,
  "health_status": "Excellent, Good, Fair, or Poor",
  "activity_level": "Very Active, Active, Moderate, Low, or Sedentary",
  "notable_features": ["Feature 1", "Feature 2", "Feature 3"],
  "mood": "Alert, Calm, Curious, Playful, etc.",
  "rarity": "Common, Uncommon, Rare, or Extremely Rare"
}

Follow the exact format above with no deviations. If you are uncertain about any value, provide your best estimate rather than omitting the field.`;

export function infoPrompt({ id, species, commonName, breed }) {
  return `You are an expert zoologist specializing in animal biology, behavior, and conservation.
I need comprehensive, accurate information about the ${breed} ${species} (Common name: ${commonName}).

Provide a detailed profile that includes:
1. Accurate scientific and taxonomic information
2. Detailed habitat information including geographic regions
3. Diet and feeding behaviors
4. Typical lifespan in wild and captivity
5. Conservation status with accurate IUCN classification
6. Detailed description of physical characteristics and adaptations
7. Typical personality traits and behaviors
8. Notable facts and interesting features about this animal
9. Challenges facing this species in the wild if applicable

Return ONLY a valid JSON object with the following fields (do not include any other text):
{
  "id": "${id}",
  "name": "${commonName}",
  "species": "${species}",
  "breed": "${breed}",
  "description": "Comprehensive description covering physical characteristics, behaviors, and notable features",
  "habitat": "Detailed natural habitat information including geographic regions",
  "diet": "Specific dietary requirements and feeding behaviors",
  "lifespan": "Typical lifespan information with range for wild vs captivity",
  "taxonomy": {
    "kingdom": "Animalia",
    "phylum": "Specific phylum",
    "class": "Specific class",
    "order": "Specific order",
    "family": "Specific family",
    "genus": "Specific genus"
  },
  "conservation": {
    "status": "IUCN classification (LC, NT, VU, EN, CR, EW, or EX)",
    "population_trend": "Increasing, Stable, or Decreasing",
    "threats": ["Threat 1", "Threat 2", "Threat 3"]
  },
  "behavior": {
    "activity_pattern": "Diurnal, Nocturnal, Crepuscular, etc.",
    "social_structure": "Solitary, Pair-bonding, Social groups, etc.",
    "personality_traits": ["Trait 1", "Trait 2", "Trait 3", "Trait 4"]
  },
  "interesting_facts": ["Fact 1", "Fact 2", "Fact 3"],
  "imageUrl": ""
}`;
}
