import { env } from '../config/env';

const CACHE_TTL = 60 * 60 * 1000; // 1 hour
const ratesCache = new Map<string, { rates: Record<string, number>; fetchedAt: number }>();

export async function getExchangeRates(baseCurrency: string): Promise<Record<string, number>> {
  const cached = ratesCache.get(baseCurrency);
  if (cached && Date.now() - cached.fetchedAt < CACHE_TTL) {
    return cached.rates;
  }

  if (!env.EXCHANGE_RATE_API_KEY) {
    console.warn('⚠️ EXCHANGE_RATE_API_KEY not set — using 1:1 rates');
    return {};
  }

  try {
    const res = await fetch(
      `https://v6.exchangerate-api.com/v6/${env.EXCHANGE_RATE_API_KEY}/latest/${baseCurrency}`
    );
    const data = (await res.json()) as { result: string; conversion_rates: Record<string, number> };

    if (data.result === 'success') {
      ratesCache.set(baseCurrency, { rates: data.conversion_rates, fetchedAt: Date.now() });
      return data.conversion_rates;
    }

    console.error('Exchange rate API error:', data);
    return {};
  } catch (error) {
    console.error('Failed to fetch exchange rates:', error);
    return {};
  }
}

export async function convertAmount(
  amount: number,
  fromCurrency: string,
  toCurrency: string
): Promise<{ convertedAmount: number; exchangeRate: number }> {
  if (fromCurrency === toCurrency) {
    return { convertedAmount: amount, exchangeRate: 1 };
  }

  const rates = await getExchangeRates(fromCurrency);
  const exchangeRate = rates[toCurrency] ?? 1;
  return { convertedAmount: Math.round(amount * exchangeRate * 100) / 100, exchangeRate };
}

export const SUPPORTED_CURRENCIES = [
  { code: 'USD', name: 'US Dollar', symbol: '$' },
  { code: 'EUR', name: 'Euro', symbol: '€' },
  { code: 'GBP', name: 'British Pound', symbol: '£' },
  { code: 'AED', name: 'UAE Dirham', symbol: 'د.إ' },
  { code: 'SAR', name: 'Saudi Riyal', symbol: '﷼' },
  { code: 'EGP', name: 'Egyptian Pound', symbol: 'E£' },
  { code: 'JPY', name: 'Japanese Yen', symbol: '¥' },
  { code: 'CAD', name: 'Canadian Dollar', symbol: 'C$' },
  { code: 'AUD', name: 'Australian Dollar', symbol: 'A$' },
  { code: 'INR', name: 'Indian Rupee', symbol: '₹' },
];
