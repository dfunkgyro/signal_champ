# Scenario Builder & Custom Route Designer

## Overview

The Scenario Builder is a powerful feature that allows users to create, share, and play custom railway scenarios. It includes a visual drag-and-drop route designer, cloud storage integration, and a community marketplace for sharing scenarios.

## Features

### 1. Visual Route Designer
- **Drag-and-drop interface** for creating custom railway layouts
- **Element types**:
  - Tracks (straight and curved)
  - Signals (traffic control)
  - Points/Switches (route selection)
  - Block Sections (safety zones)
  - Transponders (train detection)
  - WiFi Antennas (CBTC communication)
  - Stations
  - Buffers
- **Grid snapping** for precise alignment
- **Pan and zoom** controls for easy navigation
- **Properties panel** for configuring element details

### 2. Scenario Management
- **Create** new scenarios from scratch
- **Edit** existing scenarios
- **Duplicate** scenarios for quick variations
- **Delete** scenarios you own
- **Save** scenarios to Supabase cloud storage
- **Publish** scenarios to share with the community
- **Unpublish** to make scenarios private

### 3. Community Marketplace
- **Browse** featured and community scenarios
- **Search** and filter by:
  - Category (Rush Hour, Emergency, Track Maintenance, etc.)
  - Difficulty (Beginner, Intermediate, Advanced, Expert)
  - Keywords and tags
- **Download** community scenarios
- **Rate** scenarios (1-5 stars)
- **Track** download counts and ratings

### 4. Pre-built Challenge Scenarios

#### Morning Rush Hour
- **Category**: Rush Hour
- **Difficulty**: Intermediate
- **Objective**: Handle multiple trains arriving simultaneously
- **Time Limit**: 5 minutes
- **Challenges**: Signal priority management, prevent delays

#### Emergency Track Blockage
- **Category**: Emergency
- **Difficulty**: Advanced
- **Objective**: Reroute trains using alternative routes
- **Time Limit**: 5 minutes
- **Challenges**: Quick decision-making, maintain safety

#### Weekend Track Maintenance
- **Category**: Track Maintenance
- **Difficulty**: Intermediate
- **Objective**: Coordinate movements during maintenance
- **Challenges**: Limited routes, reduced speed zones

#### Basic Operations Tutorial
- **Category**: Tutorial
- **Difficulty**: Beginner
- **Objective**: Learn basic train control
- **Challenges**: Route setting, signal management

## How to Use

### Creating a New Scenario

1. **Access the Scenario Builder**
   - Click the "Scenario Builder & Marketplace" button in the app bar
   - Navigate to the "My Scenarios" tab
   - Click the "New Scenario" floating action button

2. **Design Your Layout**
   - Select an element type from the toolbar
   - Click on the canvas to place elements
   - For tracks and blocks, click start and end points
   - Click elements to select and view properties
   - Use the Delete button to remove selected elements

3. **Configure Properties**
   - Fill in the scenario name and description
   - Select a category (Rush Hour, Emergency, etc.)
   - Choose a difficulty level
   - Set canvas size, time limits, and max trains
   - Add objectives and goals

4. **Save and Test**
   - Click the Save button to save your scenario
   - Click "Test Scenario" to preview (coming soon)
   - Click "Publish" to share with the community

### Navigation Controls

- **Pan**: Drag with one finger/mouse
- **Zoom**: Pinch with two fingers or use zoom buttons
- **Reset View**: Click the center focus button
- **Snap to Grid**: Toggle for precise element placement

### Publishing Scenarios

1. Save your scenario first
2. Click the "Publish" button in the toolbar
3. Confirm publication in the dialog
4. Your scenario will appear in the community marketplace
5. Other users can download and rate your scenario

### Downloading Community Scenarios

1. Navigate to the "Community" or "Featured" tabs
2. Browse or search for scenarios
3. Click "Download" on any scenario card
4. The scenario will be copied to your "My Scenarios" collection
5. You can edit the downloaded scenario to create your own variant

## Database Schema

### scenarios Table
- **id**: UUID (primary key)
- **name**: Text
- **description**: Text
- **author_id**: UUID (foreign key to auth.users)
- **author_name**: Text
- **category**: Enum (rushHour, emergency, trackMaintenance, custom, tutorial, challenge)
- **difficulty**: Enum (beginner, intermediate, advanced, expert)
- **is_public**: Boolean
- **is_featured**: Boolean
- **created_at**: Timestamp
- **updated_at**: Timestamp
- **downloads**: Integer
- **rating**: Numeric (0-5)
- **rating_count**: Integer
- **canvas_width**: Numeric
- **canvas_height**: Numeric
- **tracks**: JSONB
- **signals**: JSONB
- **points**: JSONB
- **block_sections**: JSONB
- **train_spawns**: JSONB
- **objectives**: JSONB
- **time_limit**: Integer (seconds)
- **max_trains**: Integer
- **tags**: Text[]
- **thumbnail_url**: Text
- **metadata**: JSONB

### scenario_ratings Table
- **id**: UUID (primary key)
- **scenario_id**: UUID (foreign key to scenarios)
- **user_id**: UUID (foreign key to auth.users)
- **rating**: Numeric (0-5)
- **created_at**: Timestamp

## Security

Row Level Security (RLS) is enabled on all tables:

- **Public scenarios**: Viewable by everyone
- **Private scenarios**: Only viewable by the author
- **Creating scenarios**: Users can only create scenarios for themselves
- **Updating scenarios**: Users can only update their own scenarios
- **Deleting scenarios**: Users can only delete their own scenarios
- **Ratings**: Anyone can view, users can create/update/delete their own ratings

## API Functions

### increment_scenario_downloads(scenario_id UUID)
Increments the download count when a user duplicates a scenario.

### update_scenario_rating(scenario_id UUID)
Recalculates the average rating and rating count after a user rates a scenario.

## Future Enhancements

- [ ] Real-time multiplayer scenario editing
- [ ] Scenario templates and presets
- [ ] Advanced route validation
- [ ] Scenario leaderboards and achievements
- [ ] Video tutorials and walkthrough mode
- [ ] Import/export scenarios as JSON files
- [ ] Scenario thumbnails and preview images
- [ ] Comments and discussion on scenarios
- [ ] Scenario collections and playlists

## Technical Details

### Models
- Location: `lib/models/scenario_models.dart`
- Classes: `RailwayScenario`, `ScenarioTrack`, `ScenarioSignal`, `ScenarioPoint`, `ScenarioBlockSection`, `ScenarioTrainSpawn`, `ScenarioObjective`

### Services
- Location: `lib/services/scenario_service.dart`
- Provider: `ScenarioService` (ChangeNotifier)
- Methods: `createScenario`, `updateScenario`, `deleteScenario`, `loadMyScenarios`, `loadCommunityScenarios`, `loadFeaturedScenarios`, `publishScenario`, `duplicateScenario`, `rateScenario`

### Screens
- **Scenario Builder**: `lib/screens/scenario_builder_screen.dart`
- **Scenario Marketplace**: `lib/screens/scenario_marketplace_screen.dart`

### Widgets
- **Route Designer Canvas**: `lib/widgets/route_designer_canvas.dart`

### Database
- **Migration**: `supabase/migrations/002_scenarios.sql`

## Support

For issues, questions, or feature requests, please open an issue on the GitHub repository.
