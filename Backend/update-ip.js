#!/usr/bin/env node

/**
 * Auto-detect local IP address and update Flutter API configuration
 * Run this script whenever your network changes
 */

import { networkInterfaces } from 'os';
import { readFileSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Get local IP address (prioritizes WiFi/Ethernet over virtual adapters)
function getLocalIPAddress() {
    const nets = networkInterfaces();
    const candidates = [];

    // Collect all IPv4 addresses with their interface names
    for (const name of Object.keys(nets)) {
        for (const net of nets[name]) {
            if (net.family === 'IPv4' && !net.internal) {
                candidates.push({ name, address: net.address });
            }
        }
    }

    // Priority 1: WiFi adapters (most common for mobile development)
    const wifiAdapter = candidates.find(c =>
        c.name.toLowerCase().includes('wi-fi') ||
        c.name.toLowerCase().includes('wifi') ||
        c.name.toLowerCase().includes('wireless')
    );
    if (wifiAdapter) {
        console.log(`📡 Using WiFi adapter: ${wifiAdapter.name}`);
        return wifiAdapter.address;
    }

    // Priority 2: Ethernet adapters
    const ethernetAdapter = candidates.find(c =>
        c.name.toLowerCase().includes('ethernet') ||
        c.name.toLowerCase().includes('eth')
    );
    if (ethernetAdapter) {
        console.log(`🔌 Using Ethernet adapter: ${ethernetAdapter.name}`);
        return ethernetAdapter.address;
    }

    // Priority 3: Any 192.168.x.x address (excluding virtual adapters)
    const localNetwork = candidates.find(c =>
        c.address.startsWith('192.168.') &&
        !c.name.toLowerCase().includes('vmware') &&
        !c.name.toLowerCase().includes('virtualbox') &&
        !c.name.toLowerCase().includes('vbox')
    );
    if (localNetwork) {
        console.log(`Using network adapter: ${localNetwork.name}`);
        return localNetwork.address;
    }

    // Fallback: First non-internal IPv4
    if (candidates.length > 0) {
        console.log(`Using fallback adapter: ${candidates[0].name}`);
        return candidates[0].address;
    }

    return null;
}

// Update Flutter API configuration
function updateFlutterConfig(ipAddress, port = 3000) {
    const apiFilePath = join(__dirname, '..', 'treewayz_app', 'lib', 'servicesuwu', 'api.dart');

    try {
        let content = readFileSync(apiFilePath, 'utf8');

        // Update the baseUrl line
        const baseUrlRegex = /static const String baseUrl = "http:\/\/[^"]+";/;
        const newBaseUrl = `static const String baseUrl = "http://${ipAddress}:${port}";`;

        content = content.replace(baseUrlRegex, newBaseUrl);

        writeFileSync(apiFilePath, content, 'utf8');

        console.log('Flutter API configuration updated successfully!');
        console.log(`Backend URL: http://${ipAddress}:${port}`);
        console.log(`Updated file: ${apiFilePath}`);

        return true;
    } catch (error) {
        console.error('Error updating Flutter config:', error.message);
        return false;
    }
}

// Update backend server logging
function updateBackendConfig(ipAddress, port = 3000) {
    const serverFilePath = join(__dirname, 'server.js');

    try {
        let content = readFileSync(serverFilePath, 'utf8');

        // Update the network URL in console.log
        const networkUrlRegex = /console\.log\(`Network: http:\/\/[^`]+`\);/;
        const newNetworkUrl = `console.log(\`Network: http://${ipAddress}:\${PORT}\`);`;

        content = content.replace(networkUrlRegex, newNetworkUrl);

        writeFileSync(serverFilePath, content, 'utf8');

        console.log('Backend server configuration updated!');

        return true;
    } catch (error) {
        console.error('Could not update backend config:', error.message);
        return false;
    }
}

// Main execution
function main() {
    console.log('Detecting local IP address...\n');

    const ipAddress = getLocalIPAddress();

    if (!ipAddress) {
        console.error('Could not detect local IP address.');
        console.error('Make sure you are connected to a network.');
        process.exit(1);
    }

    console.log(`Detected IP Address: ${ipAddress}\n`);

    // Get port from environment or use default
    const port = process.env.PORT || 3000;

    // Update configurations
    const flutterUpdated = updateFlutterConfig(ipAddress, port);
    const backendUpdated = updateBackendConfig(ipAddress, port);

    if (flutterUpdated && backendUpdated) {
        console.log('\All configurations updated successfully!');
        console.log('\nNext steps:');
        console.log('   1. Restart your Flutter app (hot restart with "R")');
        console.log('   2. Make sure your phone and computer are on the same WiFi');
        console.log(`   3. Your backend is accessible at: http://${ipAddress}:${port}`);
    } else {
        console.log('\n⚠️  Some configurations could not be updated.');
        console.log('   Please check the error messages above.');
    }
}

main();
